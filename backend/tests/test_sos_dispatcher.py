"""Unit tests for Voice SOS Trigger, 10-second cancel window, and Multi-channel Escalation."""

import asyncio
import unittest
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4

from app.models.rider import EmergencyContact, Rider
from app.models.sos import SOSEvent, SOSStatusEnum, SOSTriggerTypeEnum
from app.services.sos_dispatcher import (
    DEFAULT_AUDIO_RETENTION_DAYS,
    build_emergency_message,
    cancel_sos_incident,
    confirm_and_escalate_sos,
    dispatch_unresponsive_ai_emergency,
    generate_ambulance_emergency_speech,
    generate_police_emergency_speech,
    initialize_sos_incident,
)


class TestSOSDispatcher(unittest.TestCase):
    def test_build_emergency_message_voice(self):
        """Test emergency message formatting for voice wake phrase trigger."""
        msg = build_emergency_message(
            rider_name="Aman Jha",
            trigger_type=SOSTriggerTypeEnum.voice,
            latitude=32.3712,
            longitude=77.2144,
            audio_clip_url="https://s3.amazonaws.com/roadmate/emergency_audio/clip.m4a",
            trigger_phrase="Hey RoadMate, I need help",
        )

        self.assertIn("ROADMATE EMERGENCY ALERT", msg)
        self.assertIn("Aman Jha", msg)
        self.assertIn("Voice Command ('Hey RoadMate, I need help')", msg)
        self.assertIn("32.371200, 77.214400", msg)
        self.assertIn("https://maps.google.com/?q=32.371200,77.214400", msg)
        self.assertIn("clip.m4a", msg)
        self.assertIn("112", msg)

    def test_build_emergency_message_crash_detected(self):
        """Test emergency message formatting for hard-fall crash motion trigger."""
        msg = build_emergency_message(
            rider_name="Aman Jha",
            trigger_type=SOSTriggerTypeEnum.crash_detected,
            latitude=32.3712,
            longitude=77.2144,
        )

        self.assertIn("Hard-Fall / Impact Sensor", msg)
        self.assertIn("https://maps.google.com/?q=32.371200,77.214400", msg)

    def test_initialize_sos_incident(self):
        """Verify parallel initialization queues incident without waiting for 10s cancel window."""
        db = AsyncMock()
        rider_id = uuid4()

        async def run_test():
            event = await initialize_sos_incident(
                db=db,
                rider_id=rider_id,
                trigger_type=SOSTriggerTypeEnum.voice,
                latitude=32.3712,
                longitude=77.2144,
                trigger_phrase="Hey RoadMate, I need help",
                audio_clip_url="https://s3.amazonaws.com/audio.m4a",
            )
            # Verify initial state: Active but not yet confirmed externally
            self.assertEqual(event.status, SOSStatusEnum.active)
            self.assertFalse(event.is_confirmed)
            self.assertEqual(event.escalation_stage, "pending_local_confirmation")
            self.assertIsNotNone(event.audio_expires_at)
            # Verify 30-day retention delta
            delta = event.audio_expires_at - datetime.now(timezone.utc)
            self.assertAlmostEqual(delta.days, DEFAULT_AUDIO_RETENTION_DAYS, delta=1)

        asyncio.run(run_test())

    def test_cancel_sos_incident_false_alarm(self):
        """Verify rider cancellation during 10-second local window marks event cancelled."""
        db = AsyncMock()
        event_id = uuid4()
        mock_event = SOSEvent(
            id=event_id,
            rider_id=uuid4(),
            trigger_type=SOSTriggerTypeEnum.voice,
            status=SOSStatusEnum.active,
            latitude=32.3712,
            longitude=77.2144,
            is_confirmed=False,
            escalation_stage="pending_local_confirmation",
            dispatch_log=[],
        )

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_event
        db.execute.return_value = mock_result

        async def run_test():
            cancelled = await cancel_sos_incident(
                db=db,
                event_id=event_id,
                reason="Cancelled by rider within 10-second safety window",
            )
            self.assertEqual(cancelled.status, SOSStatusEnum.cancelled)
            self.assertEqual(cancelled.escalation_stage, "cancelled")
            self.assertIsNotNone(cancelled.cancelled_at)
            self.assertEqual(cancelled.dispatch_log[-1]["action"], "incident_cancelled")

        asyncio.run(run_test())

    def test_confirm_and_escalate_sos_priority_order(self):
        """Verify multi-channel escalation runs in emergency contact priority order (1 first)."""
        db = AsyncMock()
        event_id = uuid4()
        rider_id = uuid4()

        contact1 = EmergencyContact(
            id=uuid4(),
            rider_id=rider_id,
            name="Aditi Sharma (Primary Wife)",
            phone="+919876543210",
            relationship="Spouse",
            is_primary=True,
            priority=1,
            telegram_chat_id="12345678",
        )
        contact2 = EmergencyContact(
            id=uuid4(),
            rider_id=rider_id,
            name="Vikram Rao (Captain)",
            phone="+919876543211",
            relationship="Convoy Lead",
            is_primary=False,
            priority=2,
            telegram_chat_id=None,
        )

        rider = Rider(
            id=rider_id,
            phone="+919876543200",
            name="Aman Jha",
            emergency_contacts=[contact2, contact1],  # unordered list from DB
        )

        mock_event = SOSEvent(
            id=event_id,
            rider_id=rider_id,
            trigger_type=SOSTriggerTypeEnum.voice,
            status=SOSStatusEnum.active,
            latitude=32.3712,
            longitude=77.2144,
            is_confirmed=False,
            escalation_stage="pending_local_confirmation",
            dispatch_log=[],
            rider=rider,
        )

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_event
        db.execute.return_value = mock_result

        async def run_test():
            escalated = await confirm_and_escalate_sos(db=db, event_id=event_id)
            self.assertTrue(escalated.is_confirmed)
            self.assertEqual(escalated.escalation_stage, "completed")
            self.assertIsNotNone(escalated.confirmed_at)

            # Check that contacts were logged in priority order
            dispatched_contacts = [
                entry["contact"]["contact_name"]
                for entry in escalated.dispatch_log
                if entry.get("action") == "contact_dispatched"
            ]
            self.assertEqual(
                dispatched_contacts,
                ["Aditi Sharma (Primary Wife)", "Vikram Rao (Captain)"],
            )

        asyncio.run(run_test())

    def test_generate_police_emergency_speech(self):
        """Test AI synthesized speech formatting for Police Station (112) call."""
        speech = generate_police_emergency_speech(
            rider_name="Aman Jha",
            rider_phone="+919876543200",
            blood_group="O+",
            primary_contact_name="Aditi Sharma",
            primary_contact_phone="+919876543210",
            latitude=32.3712,
            longitude=77.2144,
            location_desc="Rohtang Pass Highway NH3",
            g_force=8.4,
        )

        self.assertIn("RoadMate Indian Rider Safety Network", speech)
        self.assertIn("Aman Jha", speech)
        self.assertIn("+919876543200", speech)
        self.assertIn("O+", speech)
        self.assertIn("UNRESPONSIVE", speech)
        self.assertIn("Aditi Sharma", speech)
        self.assertIn("32.371200", speech)
        self.assertIn("77.214400", speech)
        self.assertIn("8.4G", speech)
        self.assertIn("https://maps.google.com/?q=32.371200,77.214400", speech)

    def test_generate_ambulance_emergency_speech(self):
        """Test AI synthesized speech formatting for Ambulance (108) call."""
        speech = generate_ambulance_emergency_speech(
            rider_name="Aman Jha",
            rider_phone="+919876543200",
            blood_group="O+",
            medical_notes="No drug allergies. Severe high-G trauma suspected.",
            latitude=32.3712,
            longitude=77.2144,
            location_desc="Rohtang Pass Highway NH3",
        )

        self.assertIn("Medical Emergency Priority One", speech)
        self.assertIn("Aman Jha", speech)
        self.assertIn("O+", speech)
        self.assertIn("UNRESPONSIVE", speech)
        self.assertIn("32.371200", speech)
        self.assertIn("77.214400", speech)
        self.assertIn("Advanced Life Support ambulance", speech)

    def test_dispatch_unresponsive_ai_emergency(self):
        """Verify crash escalation when rider remains unresponsive after 10-second check."""
        db = AsyncMock()
        event_id = uuid4()
        rider_id = uuid4()

        contact = EmergencyContact(
            id=uuid4(),
            rider_id=rider_id,
            name="Aditi Sharma",
            phone="+919876543210",
            relationship="Spouse",
            is_primary=True,
            priority=1,
        )

        rider = Rider(
            id=rider_id,
            phone="+919876543200",
            name="Aman Jha",
            blood_group="O+",
            emergency_contacts=[contact],
        )

        mock_event = SOSEvent(
            id=event_id,
            rider_id=rider_id,
            trigger_type=SOSTriggerTypeEnum.crash_detected,
            status=SOSStatusEnum.active,
            latitude=32.3712,
            longitude=77.2144,
            is_confirmed=False,
            is_unresponsive=False,
            police_dispatched=False,
            ambulance_dispatched=False,
            escalation_stage="pending_local_confirmation",
            dispatch_log=[],
            rider=rider,
        )

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_event
        db.execute.return_value = mock_result

        async def run_test():
            escalated = await dispatch_unresponsive_ai_emergency(
                db=db,
                event_id=event_id,
                nearest_landmark="Rohtang Pass Highway NH3",
                g_force_peak=8.4,
            )
            self.assertTrue(escalated.is_unresponsive)
            self.assertTrue(escalated.police_dispatched)
            self.assertTrue(escalated.ambulance_dispatched)
            self.assertEqual(escalated.escalation_stage, "unresponsive_escalated")
            self.assertIsNotNone(escalated.police_voice_transcript)
            self.assertIsNotNone(escalated.ambulance_voice_transcript)
            self.assertIn("Aman Jha", escalated.police_voice_transcript)
            self.assertIn("O+", escalated.ambulance_voice_transcript)
            self.assertIn("police_call", escalated.ai_voice_call_status)
            self.assertIn("ambulance_call", escalated.ai_voice_call_status)

        asyncio.run(run_test())


if __name__ == "__main__":
    unittest.main()
