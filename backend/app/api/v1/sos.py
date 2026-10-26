"""SOS Emergency Endpoints — Voice trigger, Crash detection, Parallel GPS/Audio, and Multi-channel Escalation."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_rider, get_db
from app.models.rider import Rider
from app.schemas.sos import (
    AudioRetentionUpdateRequest,
    SOSCancelRequest,
    SOSConfirmRequest,
    SOSEventOut,
    SOSTriggerRequest,
    UnresponsiveCrashEscalationRequest,
    UnresponsiveCrashEscalationResponse,
)
from app.services.sos_dispatcher import (
    attach_audio_clip,
    cancel_sos_incident,
    confirm_and_escalate_sos,
    dispatch_unresponsive_ai_emergency,
    initialize_sos_incident,
)
from app.services.storage import upload_file

router = APIRouter(prefix="/sos", tags=["Emergency SOS"])


@router.post("/trigger", response_model=SOSEventOut, status_code=status.HTTP_201_CREATED)
async def trigger_sos(
    payload: SOSTriggerRequest,
    current_rider: Rider = Depends(get_current_rider),
    db: AsyncSession = Depends(get_db),
) -> SOSEventOut:
    """Trigger an emergency incident via Voice ("Hey RoadMate, I need help"), Crash motion, or Manual button.
    
    Immediately captures GPS, creates incident record, and queues emergency contacts in parallel.
    The local 10-second cancel window does NOT block this initial queueing.
    """
    sos_event = await initialize_sos_incident(
        db=db,
        rider_id=current_rider.id,
        trigger_type=payload.trigger_type,
        latitude=payload.latitude,
        longitude=payload.longitude,
        location_trail=payload.location_trail,
        group_ride_id=payload.group_ride_id,
        trigger_phrase=payload.trigger_phrase,
        audio_clip_url=payload.audio_clip_url,
    )
    return SOSEventOut.model_validate(sos_event)


@router.post("/{event_id}/confirm", response_model=SOSEventOut)
async def confirm_sos(
    event_id: UUID,
    payload: SOSConfirmRequest,
    current_rider: Rider = Depends(get_current_rider),
    db: AsyncSession = Depends(get_db),
) -> SOSEventOut:
    """Invoked when the 10-second local cancel window expires without rider cancellation.
    
    Initiates parallel multi-channel escalation:
    1. High-priority push notifications to emergency contacts.
    2. SMS gateway fallback with GPS link, map pin, and audio clip.
    3. Telegram bonus channel.
    """
    sos_event = await confirm_and_escalate_sos(db=db, event_id=event_id)
    if not sos_event:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="SOS event not found")
    return SOSEventOut.model_validate(sos_event)


@router.post("/{event_id}/cancel", response_model=SOSEventOut)
async def cancel_sos(
    event_id: UUID,
    payload: SOSCancelRequest,
    current_rider: Rider = Depends(get_current_rider),
    db: AsyncSession = Depends(get_db),
) -> SOSEventOut:
    """Cancel emergency dispatch if rider aborts during the 10-second local window or false alarm."""
    sos_event = await cancel_sos_incident(db=db, event_id=event_id, reason=payload.reason)
    if not sos_event:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="SOS event not found")
    return SOSEventOut.model_validate(sos_event)


@router.post("/{event_id}/audio", response_model=SOSEventOut)
async def upload_emergency_audio(
    event_id: UUID,
    audio_file: UploadFile = File(...),
    current_rider: Rider = Depends(get_current_rider),
    db: AsyncSession = Depends(get_db),
) -> SOSEventOut:
    """Upload short ~30-60 second encrypted ambient audio clip recorded on trigger.
    
    Audio is stored with an automated 30-day retention window per privacy policies.
    """
    contents = await audio_file.read()
    content_type = audio_file.content_type or "audio/m4a"
    audio_url = upload_file(
        file_data=contents,
        folder="emergency_audio",
        filename=f"sos_{event_id}_{int(audio_file.size or len(contents))}.m4a",
        content_type=content_type,
    )

    sos_event = await attach_audio_clip(db=db, event_id=event_id, audio_clip_url=audio_url)
    if not sos_event:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="SOS event not found")
    return SOSEventOut.model_validate(sos_event)


@router.patch("/{event_id}/retention", response_model=SOSEventOut)
async def update_audio_retention(
    event_id: UUID,
    payload: AudioRetentionUpdateRequest,
    current_rider: Rider = Depends(get_current_rider),
    db: AsyncSession = Depends(get_db),
) -> SOSEventOut:
    """Rider can mark an incident audio clip to be kept permanently rather than auto-deleted in 30 days."""
    from sqlalchemy import select
    from app.models.sos import SOSEvent

    stmt = select(SOSEvent).where(SOSEvent.id == event_id, SOSEvent.rider_id == current_rider.id)
    res = await db.execute(stmt)
    event = res.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="SOS event not found")

    event.keep_audio_permanently = payload.keep_permanently
    if payload.keep_permanently:
        event.audio_expires_at = None
    await db.commit()
    await db.refresh(event)
    return SOSEventOut.model_validate(event)


@router.post("/{event_id}/unresponsive-escalation", response_model=UnresponsiveCrashEscalationResponse)
async def escalate_unresponsive_crash_event(
    event_id: UUID,
    payload: UnresponsiveCrashEscalationRequest,
    current_rider: Rider = Depends(get_current_rider),
    db: AsyncSession = Depends(get_db),
) -> UnresponsiveCrashEscalationResponse:
    """Invoked when 10 seconds elapse following a major crash and rider remains unresponsive.
    
    Concurrently:
    1. AI Voice calls Police Station (112) with rider identity, coordinates, and unresponsiveness report.
    2. AI Voice calls Ambulance (108) with trauma severity, blood group, medical notes, and live GPS link.
    3. Multi-channel SMS/Push dispatch to emergency contacts.
    """
    sos_event = await dispatch_unresponsive_ai_emergency(
        db=db,
        event_id=event_id,
        nearest_landmark=payload.nearest_landmark,
        g_force_peak=payload.g_force_peak,
    )
    if not sos_event:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="SOS event not found")

    contacts_count = len(getattr(sos_event.rider, "emergency_contacts", []))
    map_url = f"https://maps.google.com/?q={sos_event.latitude:.6f},{sos_event.longitude:.6f}"

    return UnresponsiveCrashEscalationResponse(
        event_id=sos_event.id,
        status="unresponsive_escalated",
        is_unresponsive=True,
        police_dispatched=sos_event.police_dispatched,
        ambulance_dispatched=sos_event.ambulance_dispatched,
        police_voice_transcript=sos_event.police_voice_transcript or "",
        ambulance_voice_transcript=sos_event.ambulance_voice_transcript or "",
        map_url=map_url,
        emergency_contacts_alerted=contacts_count,
        timestamp=sos_event.confirmed_at or sos_event.created_at,
    )


@router.get("/{event_id}/voice-transcripts")
async def get_emergency_voice_transcripts(
    event_id: UUID,
    current_rider: Rider = Depends(get_current_rider),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve full AI synthesized speech transcripts and call status for Police (112) and Ambulance (108)."""
    from sqlalchemy import select
    from app.models.sos import SOSEvent

    stmt = select(SOSEvent).where(SOSEvent.id == event_id)
    res = await db.execute(stmt)
    event = res.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="SOS event not found")

    return {
        "event_id": str(event.id),
        "is_unresponsive": event.is_unresponsive,
        "police_dispatched": event.police_dispatched,
        "ambulance_dispatched": event.ambulance_dispatched,
        "police_voice_transcript": event.police_voice_transcript,
        "ambulance_voice_transcript": event.ambulance_voice_transcript,
        "ai_voice_call_status": event.ai_voice_call_status,
        "escalation_stage": event.escalation_stage,
        "dispatch_log": event.dispatch_log,
    }

