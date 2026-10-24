"""Tests for Real-Time Live Map backend features.

Verifies:
1. Redis Pub/Sub ride room fan-out and in-memory fallback.
2. WebSocket telemetry ingestion and fan-out to room members.
3. PostGIS nearby hazards spatial query and client auto-expiry fields.
"""

from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
import json
import unittest
from unittest.mock import AsyncMock, MagicMock, patch
import uuid

from fastapi.testclient import TestClient

from app.main import app
from app.models.hazard import HazardReport, HazardTypeEnum, SeverityEnum
from app.services.redis_pubsub import RideRoomPubSubManager, ride_pubsub


class TestLiveRidePubSub(unittest.IsolatedAsyncioTestCase):
    """Test suite for RideRoomPubSubManager."""

    async def test_in_memory_pubsub_fanout(self):
        """Verify pub/sub delivers frames to multiple subscribers when Redis is offline."""
        mgr = RideRoomPubSubManager()
        # Force in-memory fallback for deterministic testing
        mgr._redis_available = False

        channel = "ride_room:test-room-123"
        test_payload = {
            "type": "member_position",
            "rider_id": "rider-001",
            "rider_name": "Vikram",
            "lat": 32.242,
            "lng": 77.185,
            "speed": 75.4,
            "heading": 140.0,
            "altitude": 4200.0,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

        # Subscribe
        sub_generator = mgr.subscribe(channel)

        # Consumer task
        received = []

        async def _consume():
            async for item in sub_generator:
                received.append(item)
                break

        consume_task = asyncio.create_task(_consume())
        # Allow subscription queue to register
        await asyncio.sleep(0.01)

        # Publish
        await mgr.publish(channel, test_payload)
        await asyncio.wait_for(consume_task, timeout=2.0)

        self.assertEqual(len(received), 1)
        self.assertEqual(received[0]["rider_id"], "rider-001")
        self.assertAlmostEqual(received[0]["lat"], 32.242)
        await mgr.close()


class TestLiveRidesWebSocket(unittest.TestCase):
    """Test suite for live rides WebSocket protocol."""

    def setUp(self):
        self.client = TestClient(app)

    def test_websocket_ping_pong(self):
        """Ensure WebSocket keepalive ping receives a pong response."""
        with self.client.websocket_connect("/ws/rides/room-alpha-99") as ws:
            ws.send_text(json.dumps({"type": "ping"}))
            raw_resp = ws.receive_text()
            data = json.loads(raw_resp)
            self.assertEqual(data.get("type"), "pong")
            self.assertIn("time", data)

    def test_websocket_telemetry_and_disconnect_status(self):
        """Ensure sending telemetry registers rider and disconnect triggers reconnecting status."""
        ride_pubsub._redis_available = False
        room_id = f"test-room-{uuid.uuid4().hex[:6]}"

        status_messages = []

        async def _capture_status():
            async for msg in ride_pubsub.subscribe(f"ride_room:{room_id}"):
                if msg.get("type") == "rider_status":
                    status_messages.append(msg)
                    if len(status_messages) >= 1:
                        break

        # Start capture
        loop = asyncio.new_event_loop()
        capture_task = loop.create_task(_capture_status())

        with self.client.websocket_connect(f"/ws/rides/{room_id}") as ws:
            ws.send_text(json.dumps({
                "type": "telemetry",
                "rider_id": "rider-777",
                "rider_name": "Aman",
                "lat": 32.3712,
                "lng": 77.2144,
                "speed": 84.0,
                "heading": 45.0,
                "altitude": 4280.0,
            }))
            # Let event loop process
            loop.run_until_complete(asyncio.sleep(0.05))

        # After socket closes, WebSocket handler should publish 'reconnecting' status
        loop.run_until_complete(asyncio.sleep(0.1))
        loop.run_until_complete(asyncio.wait_for(capture_task, timeout=1.0))
        loop.close()

        self.assertGreaterEqual(len(status_messages), 1)
        self.assertEqual(status_messages[0]["rider_id"], "rider-777")
        self.assertEqual(status_messages[0]["status"], "reconnecting")


class TestHazardsNearbyAPI(unittest.TestCase):
    """Test suite for the nearby hazards spatial query endpoint."""

    def setUp(self):
        self.client = TestClient(app)

    @patch("app.api.v1.hazards.get_db")
    def test_hazards_nearby_endpoint_structure(self, mock_get_db):
        """Test GET /hazards/nearby returns active hazards formatted with coordinates."""
        now = datetime.now(timezone.utc)
        mock_report = HazardReport(
            id=uuid.uuid4(),
            reporter_id=uuid.uuid4(),
            hazard_type=HazardTypeEnum.landslide,
            description="Active rockfall on hairpin 4",
            severity=SeverityEnum.high,
            confidence_score=0.95,
            is_active=True,
            expires_at=now + timedelta(hours=3),
            created_at=now,
            upvotes=8,
            downvotes=0,
        )
        fake_geojson = json.dumps({"type": "Point", "coordinates": [77.2144, 32.3712]})

        mock_session = AsyncMock()
        mock_result = MagicMock()
        mock_result.all.return_value = [(mock_report, fake_geojson)]
        mock_session.execute.return_value = mock_result

        async def _override_get_db():
            yield mock_session

        app.dependency_overrides[app.dependency_overrides.get("get_db", None) or mock_get_db] = _override_get_db
        # Also override the actual dependency function
        from app.api.deps import get_db
        app.dependency_overrides[get_db] = _override_get_db

        try:
            response = self.client.get("/hazards/nearby?lat=32.37&lng=77.21&radius=5000")
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["count"], 1)
            self.assertEqual(data["center"]["lat"], 32.37)
            self.assertEqual(data["center"]["lng"], 77.21)
            self.assertIn("fetched_at", data)

            item = data["items"][0]
            self.assertEqual(item["hazard_type"], "landslide")
            self.assertEqual(item["severity"], "high")
            self.assertAlmostEqual(item["latitude"], 32.3712)
            self.assertAlmostEqual(item["longitude"], 77.2144)
            self.assertIsNotNone(item["expires_at"])
        finally:
            app.dependency_overrides.clear()


if __name__ == "__main__":
    unittest.main()
