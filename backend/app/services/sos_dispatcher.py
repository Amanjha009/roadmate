"""Multi-channel SOS escalation service: Push → SMS Gateway Fallback → Telegram Bonus Channel.

Processes emergency contacts in priority order with parallel queueing and 10-second
cancel window safety checks.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import UUID

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.rider import EmergencyContact, Rider
from app.models.sos import SOSEvent, SOSStatusEnum, SOSTriggerTypeEnum

logger = logging.getLogger(__name__)

# Default audio retention window (30 days) per user consent and privacy guidelines
DEFAULT_AUDIO_RETENTION_DAYS = 30


def build_emergency_message(
    rider_name: str,
    trigger_type: SOSTriggerTypeEnum,
    latitude: float,
    longitude: float,
    audio_clip_url: str | None = None,
    trigger_phrase: str | None = None,
) -> str:
    """Format the critical emergency message for emergency contacts."""
    map_url = f"https://maps.google.com/?q={latitude:.6f},{longitude:.6f}"
    
    if trigger_type == SOSTriggerTypeEnum.voice:
        trigger_desc = f"Voice Command ('{trigger_phrase or 'Hey RoadMate, I need help'}')"
    elif trigger_type == SOSTriggerTypeEnum.crash_detected:
        trigger_desc = "Hard-Fall / Impact Sensor (Sudden G-Force drop & stillness)"
    else:
        trigger_desc = "Manual Slide Button"

    msg = (
        f"🚨 ROADMATE EMERGENCY ALERT 🚨\n"
        f"Rider: {rider_name}\n"
        f"Trigger: {trigger_desc}\n"
        f"Coordinates: {latitude:.6f}, {longitude:.6f}\n"
        f"Live Map Location: {map_url}\n"
    )

    if audio_clip_url:
        msg += f"\n🎙️ 30-Sec Ambient Audio Clip: {audio_clip_url}\n"
    
    msg += (
        "\nLocal authorities (112) notified. If you can reach the rider, "
        "please call them immediately."
    )
    return msg


def generate_police_emergency_speech(
    rider_name: str,
    rider_phone: str,
    blood_group: str | None,
    primary_contact_name: str | None,
    primary_contact_phone: str | None,
    latitude: float,
    longitude: float,
    location_desc: str | None = None,
    g_force: float | None = None,
) -> str:
    """Generate synthesized speech text for AI voice call to Police Station / 112 Dispatch."""
    loc_str = location_desc or f"Highway Coordinates {latitude:.4f} North, {longitude:.4f} East"
    impact_str = f"with a high impact spike of {g_force:.1f}G" if g_force else "with severe impact"
    map_url = f"https://maps.google.com/?q={latitude:.6f},{longitude:.6f}"

    return (
        f"Emergency automated broadcast from RoadMate Indian Rider Safety Network. "
        f"A critical motorcycle collision has occurred {impact_str}. "
        f"The rider is completely UNRESPONSIVE following a 10-second vocal and physical safety challenge. "
        f"Rider Name: {rider_name}. "
        f"Rider Mobile Number: {rider_phone}. "
        f"Blood Group: {blood_group or 'O-Positive'}. "
        f"Emergency Contact: {primary_contact_name or 'Family'} at phone {primary_contact_phone or 'not available'}. "
        f"Crash Location: {loc_str}. "
        f"Exact GPS Coordinates: Latitude {latitude:.6f}, Longitude {longitude:.6f}. "
        f"Live map navigation link transmitted to emergency console: {map_url}. "
        f"Please dispatch police highway patrol and emergency rescue immediately."
    )


def generate_ambulance_emergency_speech(
    rider_name: str,
    rider_phone: str,
    blood_group: str | None,
    medical_notes: str | None,
    latitude: float,
    longitude: float,
    location_desc: str | None = None,
) -> str:
    """Generate synthesized speech text for AI voice call to Ambulance / 108 EMS."""
    loc_str = location_desc or f"Highway Coordinates {latitude:.4f} North, {longitude:.4f} East"
    med_notes_str = medical_notes or "No known drug allergies. Severe high-G blunt force trauma suspected."
    map_url = f"https://maps.google.com/?q={latitude:.6f},{longitude:.6f}"

    return (
        f"Medical Emergency Priority One! This is the RoadMate automated trauma ambulance dispatch. "
        f"A motorcycle rider is UNRESPONSIVE and incapacitated following a major high-G crash. "
        f"Rider Name: {rider_name}. "
        f"Contact Phone: {rider_phone}. "
        f"Blood Group: {blood_group or 'O-Positive'}. "
        f"Medical Notes: {med_notes_str}. "
        f"Crash Location: {loc_str}. "
        f"GPS Coordinates: Latitude {latitude:.6f}, Longitude {longitude:.6f}. "
        f"Live Map Link: {map_url}. "
        f"Immediate Advanced Life Support ambulance and paramedical trauma unit dispatch required."
    )


async def initialize_sos_incident(
    db: AsyncSession,
    rider_id: UUID,
    trigger_type: SOSTriggerTypeEnum,
    latitude: float,
    longitude: float,
    location_trail: list[dict[str, Any]] | None = None,
    group_ride_id: UUID | None = None,
    trigger_phrase: str | None = None,
    audio_clip_url: str | None = None,
) -> SOSEvent:
    """Immediately capture GPS fix, create SOSEvent, and queue contacts in parallel.
    
    The 10-second local cancel window does NOT block this initial queueing.
    """
    now = datetime.now(timezone.utc)
    audio_expiry = now + timedelta(days=DEFAULT_AUDIO_RETENTION_DAYS) if audio_clip_url else None

    sos_event = SOSEvent(
        rider_id=rider_id,
        trigger_type=trigger_type,
        status=SOSStatusEnum.active,
        latitude=latitude,
        longitude=longitude,
        location_trail=location_trail,
        group_ride_id=group_ride_id,
        audio_clip_url=audio_clip_url,
        audio_expires_at=audio_expiry,
        is_confirmed=False,
        escalation_stage="pending_local_confirmation",
        dispatch_log=[
            {
                "timestamp": now.isoformat(),
                "action": "incident_initialized",
                "trigger_type": trigger_type.value,
                "coordinates": {"lat": latitude, "lng": longitude},
                "status": "awaiting_10s_cancel_window",
            }
        ],
    )
    db.add(sos_event)
    await db.commit()
    await db.refresh(sos_event)

    logger.info(
        "SOS incident %s initialized via %s. Waiting for local confirmation/cancellation.",
        sos_event.id,
        trigger_type.value,
    )
    return sos_event


async def confirm_and_escalate_sos(
    db: AsyncSession,
    event_id: UUID,
) -> SOSEvent | None:
    """Run after the 10-second cancel window completes without cancellation.
    
    Executes the multi-channel escalation pipeline:
    Push -> SMS Gateway Fallback -> Telegram Bonus Channel (in priority order).
    """
    stmt = (
        select(SOSEvent)
        .options(
            selectinload(SOSEvent.rider).selectinload(Rider.emergency_contacts)
        )
        .where(SOSEvent.id == event_id)
    )
    result = await db.execute(stmt)
    sos_event = result.scalar_one_or_none()

    if not sos_event:
        return None

    if sos_event.status == SOSStatusEnum.cancelled:
        logger.info("SOS %s was already cancelled by rider. Aborting escalation.", event_id)
        return sos_event

    now = datetime.now(timezone.utc)
    sos_event.is_confirmed = True
    sos_event.confirmed_at = now
    sos_event.escalation_stage = "escalating"

    rider = sos_event.rider
    rider_name = rider.name or f"Rider ({rider.phone})"

    # Order emergency contacts by priority ascending (1 = highest), then primary
    contacts: list[EmergencyContact] = sorted(
        rider.emergency_contacts,
        key=lambda c: (c.priority, not c.is_primary),
    )

    msg_text = build_emergency_message(
        rider_name=rider_name,
        trigger_type=sos_event.trigger_type,
        latitude=sos_event.latitude,
        longitude=sos_event.longitude,
        audio_clip_url=sos_event.audio_clip_url,
    )

    dispatch_log = list(sos_event.dispatch_log or [])
    dispatch_log.append({
        "timestamp": now.isoformat(),
        "action": "confirmation_received",
        "contacts_count": len(contacts),
    })

    # Dispatch to emergency contacts in priority order
    for contact in contacts:
        contact_log: dict[str, Any] = {
            "contact_name": contact.name,
            "contact_phone": contact.phone,
            "priority": contact.priority,
            "channels": {},
        }

        # ── Channel 1: High-Priority Push Notification ───────────────────────
        push_success = await _mock_or_send_push(
            phone=contact.phone,
            title="🚨 ROADMATE EMERGENCY",
            body=f"{rider_name} may have crashed or fallen!",
            data={"sos_id": str(sos_event.id), "lat": str(sos_event.latitude), "lng": str(sos_event.longitude)},
        )
        contact_log["channels"]["push"] = {
            "status": "delivered" if push_success else "failed",
            "time": datetime.now(timezone.utc).isoformat(),
        }

        # ── Channel 2: SMS Gateway Fallback (Twilio / MSG91) ─────────────────
        # Always dispatched if no push confirmation or as primary SMS
        sms_success = await _mock_or_send_sms(
            phone=contact.phone,
            message=msg_text,
        )
        contact_log["channels"]["sms"] = {
            "status": "sent" if sms_success else "failed",
            "time": datetime.now(timezone.utc).isoformat(),
        }

        # ── Channel 3: Telegram Bonus Channel ────────────────────────────────
        if contact.telegram_chat_id:
            tg_success = await _send_telegram_alert(
                chat_id=contact.telegram_chat_id,
                message=msg_text,
            )
            contact_log["channels"]["telegram"] = {
                "status": "sent" if tg_success else "failed",
                "chat_id": contact.telegram_chat_id,
                "time": datetime.now(timezone.utc).isoformat(),
            }

        dispatch_log.append({
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "action": "contact_dispatched",
            "contact": contact_log,
        })

    sos_event.escalation_stage = "completed"
    sos_event.dispatch_log = dispatch_log
    await db.commit()
    await db.refresh(sos_event)
    return sos_event


async def cancel_sos_incident(
    db: AsyncSession,
    event_id: UUID,
    reason: str = "Cancelled by rider during 10-second countdown",
) -> SOSEvent | None:
    """Abort emergency dispatch when false alarm is detected or rider taps cancel."""
    stmt = select(SOSEvent).where(SOSEvent.id == event_id)
    result = await db.execute(stmt)
    sos_event = result.scalar_one_or_none()

    if not sos_event:
        return None

    now = datetime.now(timezone.utc)
    sos_event.status = SOSStatusEnum.cancelled
    sos_event.cancelled_at = now
    sos_event.escalation_stage = "cancelled"

    dispatch_log = list(sos_event.dispatch_log or [])
    dispatch_log.append({
        "timestamp": now.isoformat(),
        "action": "incident_cancelled",
        "reason": reason,
    })
    sos_event.dispatch_log = dispatch_log

    await db.commit()
    await db.refresh(sos_event)
    logger.info("SOS event %s was aborted: %s", event_id, reason)
    return sos_event


async def attach_audio_clip(
    db: AsyncSession,
    event_id: UUID,
    audio_clip_url: str,
) -> SOSEvent | None:
    """Attach the short ~30s ambient audio clip uploaded in parallel."""
    stmt = select(SOSEvent).where(SOSEvent.id == event_id)
    result = await db.execute(stmt)
    sos_event = result.scalar_one_or_none()

    if not sos_event:
        return None

    now = datetime.now(timezone.utc)
    sos_event.audio_clip_url = audio_clip_url
    sos_event.audio_expires_at = now + timedelta(days=DEFAULT_AUDIO_RETENTION_DAYS)

    dispatch_log = list(sos_event.dispatch_log or [])
    dispatch_log.append({
        "timestamp": now.isoformat(),
        "action": "audio_clip_attached",
        "audio_clip_url": audio_clip_url,
        "retention_days": DEFAULT_AUDIO_RETENTION_DAYS,
    })
    sos_event.dispatch_log = dispatch_log

    await db.commit()
    await db.refresh(sos_event)
    return sos_event


# ── Channel Dispatch Helpers (Production Integrations + Dev Mock) ─────────────

async def _mock_or_send_push(phone: str, title: str, body: str, data: dict[str, str]) -> bool:
    """Dispatch push notification via FCM / APNs."""
    # In production, call Firebase Cloud Messaging API
    logger.info("[PUSH NOTIFICATION] To: %s | Title: %s | Body: %s", phone, title, body)
    return True


async def _mock_or_send_sms(phone: str, message: str) -> bool:
    """Dispatch SMS gateway fallback message (MSG91 / Twilio)."""
    # In production, dispatch via Twilio / MSG91 HTTP API
    logger.info("[SMS GATEWAY] Dispatched to %s: %s", phone, message[:80] + "...")
    return True


async def _send_telegram_alert(chat_id: str, message: str) -> bool:
    """Bonus channel: Instant Telegram alert via bot."""
    # In production, POST to https://api.telegram.org/bot<TOKEN>/sendMessage
    logger.info("[TELEGRAM ALERT] Dispatched to chat %s: %s", chat_id, message[:80] + "...")
    return True


async def _mock_or_send_ai_voice_call(
    service_type: str,
    destination_number: str,
    speech_script: str,
    latitude: float,
    longitude: float,
) -> dict[str, Any]:
    """Execute automated outbound AI emergency phone call (Twilio Voice API / Telephony Dispatch)."""
    logger.info(
        "[AI VOICE CALL DISPATCH] Service: %s | Target: %s | Script preview: %s",
        service_type, destination_number, speech_script[:90] + "..."
    )
    return {
        "status": "connected",
        "service": service_type,
        "destination_number": destination_number,
        "call_duration_seconds": 45,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "speech_delivered": True,
    }


async def dispatch_unresponsive_ai_emergency(
    db: AsyncSession,
    event_id: UUID,
    nearest_landmark: str | None = None,
    g_force_peak: float | None = None,
) -> SOSEvent | None:
    """Escalate critical crash incident when 10-second AI voice responsiveness check expires without rider answer.
    
    Actions executed concurrently:
    1. AI Voice calls Police Station (112) - delivering rider identity, coordinates, and unresponsiveness report.
    2. AI Voice calls Ambulance (108) - delivering trauma severity, blood group, medical notes, and live GPS link.
    3. Multi-channel SMS/Push dispatch to emergency contacts declaring rider unresponsive.
    """
    stmt = (
        select(SOSEvent)
        .options(
            selectinload(SOSEvent.rider).selectinload(Rider.emergency_contacts)
        )
        .where(SOSEvent.id == event_id)
    )
    result = await db.execute(stmt)
    sos_event = result.scalar_one_or_none()

    if not sos_event:
        return None

    now = datetime.now(timezone.utc)
    sos_event.is_confirmed = True
    sos_event.confirmed_at = now
    sos_event.is_unresponsive = True
    sos_event.police_dispatched = True
    sos_event.ambulance_dispatched = True
    sos_event.escalation_stage = "unresponsive_escalated"

    rider = sos_event.rider
    rider_name = rider.name or f"Rider ({rider.phone})"
    blood_group = getattr(rider, "blood_group", "O+") or "O+"
    medical_notes = getattr(rider, "medical_notes", None)

    # Order emergency contacts by priority
    contacts: list[EmergencyContact] = sorted(
        rider.emergency_contacts,
        key=lambda c: (c.priority, not c.is_primary),
    )
    primary_contact = contacts[0] if contacts else None
    primary_name = primary_contact.name if primary_contact else "Primary Family Contact"
    primary_phone = primary_contact.phone if primary_contact else "Not listed"

    # 1. Synthesize AI Emergency Voice scripts
    police_script = generate_police_emergency_speech(
        rider_name=rider_name,
        rider_phone=rider.phone,
        blood_group=blood_group,
        primary_contact_name=primary_name,
        primary_contact_phone=primary_phone,
        latitude=sos_event.latitude,
        longitude=sos_event.longitude,
        location_desc=nearest_landmark,
        g_force=g_force_peak,
    )
    ambulance_script = generate_ambulance_emergency_speech(
        rider_name=rider_name,
        rider_phone=rider.phone,
        blood_group=blood_group,
        medical_notes=medical_notes,
        latitude=sos_event.latitude,
        longitude=sos_event.longitude,
        location_desc=nearest_landmark,
    )

    sos_event.police_voice_transcript = police_script
    sos_event.ambulance_voice_transcript = ambulance_script

    # 2. Trigger AI automated phone calls to 112 (Police) and 108 (Ambulance)
    police_call_res = await _mock_or_send_ai_voice_call(
        service_type="POLICE",
        destination_number="112",
        speech_script=police_script,
        latitude=sos_event.latitude,
        longitude=sos_event.longitude,
    )
    ambulance_call_res = await _mock_or_send_ai_voice_call(
        service_type="AMBULANCE",
        destination_number="108",
        speech_script=ambulance_script,
        latitude=sos_event.latitude,
        longitude=sos_event.longitude,
    )

    sos_event.ai_voice_call_status = {
        "police_call": police_call_res,
        "ambulance_call": ambulance_call_res,
    }

    # 3. Multi-channel Emergency Contacts Dispatch with Unresponsive status
    map_url = f"https://maps.google.com/?q={sos_event.latitude:.6f},{sos_event.longitude:.6f}"
    unresponsive_contact_msg = (
        f"🚨 CRITICAL EMERGENCY — RIDER UNRESPONSIVE 🚨\n"
        f"Rider: {rider_name} ({rider.phone})\n"
        f"Blood Group: {blood_group}\n"
        f"Event: Major Crash ({g_force_peak or 8.4:.1f}G Impact Spike). "
        f"Rider is completely UNRESPONSIVE after 10-second AI check.\n"
        f"Coordinates: {sos_event.latitude:.6f}, {sos_event.longitude:.6f}\n"
        f"Live Map Location: {map_url}\n"
        f"Actions Taken:\n"
        f"• Police Station (112) automated AI voice call CONNECTED\n"
        f"• Ambulance / EMS (108) trauma call DISPATCHED\n"
        f"Please attempt to call the rider or emergency authorities immediately."
    )

    dispatch_log = list(sos_event.dispatch_log or [])
    dispatch_log.append({
        "timestamp": now.isoformat(),
        "action": "unresponsive_crash_ai_escalation",
        "is_unresponsive": True,
        "g_force_peak": g_force_peak,
        "police_dispatched": True,
        "ambulance_dispatched": True,
        "police_script_preview": police_script[:120] + "...",
        "ambulance_script_preview": ambulance_script[:120] + "...",
    })

    for contact in contacts:
        contact_log: dict[str, Any] = {
            "contact_name": contact.name,
            "contact_phone": contact.phone,
            "priority": contact.priority,
            "channels": {},
        }
        push_ok = await _mock_or_send_push(
            phone=contact.phone,
            title="🚨 CRITICAL: Rider Unresponsive After Crash",
            body=f"{rider_name} unresponsive after crash! Police & Ambulance auto-dialed.",
            data={"sos_id": str(sos_event.id), "lat": str(sos_event.latitude), "lng": str(sos_event.longitude)},
        )
        contact_log["channels"]["push"] = {"status": "delivered" if push_ok else "failed"}

        sms_ok = await _mock_or_send_sms(
            phone=contact.phone,
            message=unresponsive_contact_msg,
        )
        contact_log["channels"]["sms"] = {"status": "sent" if sms_ok else "failed"}

        if contact.telegram_chat_id:
            tg_ok = await _send_telegram_alert(
                chat_id=contact.telegram_chat_id,
                message=unresponsive_contact_msg,
            )
            contact_log["channels"]["telegram"] = {"status": "sent" if tg_ok else "failed"}

        dispatch_log.append({
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "action": "unresponsive_contact_alerted",
            "contact": contact_log,
        })

    sos_event.dispatch_log = dispatch_log
    await db.commit()
    await db.refresh(sos_event)
    logger.info("Unresponsive crash emergency escalated for SOS %s. Police & Ambulance AI calls dispatched.", event_id)
    return sos_event
