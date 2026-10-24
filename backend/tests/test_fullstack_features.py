"""Automated test suite for Master Full-Stack Feature Expansion.

Verifies:
1. GPS spike rejection (>50m accuracy, >220 km/h velocity, <3m drift, null vs 0 altitude)
2. Privacy geofence 500m start/end polyline clipping
3. Hazard idempotency (duplicate prevention on flaky mountain networks)
4. Anti-spam proximity guard (voter within 5 km enforced; >5 km rejected; 1-vote-per-rider)
5. Personal fuel range & dry-zone deficit math with high-altitude degradation disclaimer
6. Offline convoy sync deduplication with UUID event keys and freshness states
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
import json
import unittest
from unittest.mock import AsyncMock, MagicMock, patch
import uuid

from fastapi.testclient import TestClient

from app.api.v1.convoy_sync import evaluate_freshness
from app.api.v1.hazards import compute_hazard_confidence, haversine_distance_meters
from app.api.v1.ridestory import clip_privacy_geofence, filter_gps_points
from app.api.v1.touring_support import calculate_fuel_range
from app.main import app
from app.models.hazard import HazardLifecycleEnum, HazardReport, HazardTypeEnum, SeverityEnum
from app.schemas.convoy_sync import BatchSyncRequest, OfflineTelemetryPoint
from app.schemas.touring import FuelRangeRequest


class TestFullStackFeatureExpansion(unittest.IsolatedAsyncioTestCase):
    """Test suite covering all 4 core expanded pillars."""

    def setUp(self):
        self.client = TestClient(app)

    # ─────────────────────────────────────────────────────────────
    # 1. GPS SPIKE REJECTION & PRIVACY GEOFENCE CLIPPING
    # ─────────────────────────────────────────────────────────────

    def test_gps_spike_and_drift_rejection(self):
        """Verify Haversine + Velocity filter rejects accuracy >50m, velocity >220 km/h, and drift <3m."""
        base_t = datetime.now(timezone.utc)

        raw_fixes = [
            # 1. Valid starting fix at Manali
            {"lat": 32.242, "lng": 77.185, "altitude": 2050.0, "speed_kmh": 40.0, "accuracy_m": 8.0, "timestamp": base_t.isoformat()},
            # 2. Inaccurate fix (accuracy > 50m) -> MUST BE REJECTED
            {"lat": 32.245, "lng": 77.189, "altitude": 2060.0, "speed_kmh": 45.0, "accuracy_m": 85.0, "timestamp": (base_t + timedelta(seconds=5)).isoformat()},
            # 3. Teleportation velocity spike (> 220 km/h: moved 20 km in 2s = 36,000 km/h) -> MUST BE REJECTED
            {"lat": 32.400, "lng": 77.400, "altitude": 3200.0, "speed_kmh": 260.0, "accuracy_m": 5.0, "timestamp": (base_t + timedelta(seconds=7)).isoformat()},
            # 4. Stationary GPS flutter / drift (< 3m moved while stationary) -> MUST BE FILTERED
            {"lat": 32.242005, "lng": 77.185005, "altitude": 2050.0, "speed_kmh": 0.5, "accuracy_m": 4.0, "timestamp": (base_t + timedelta(seconds=12)).isoformat()},
            # 5. Legitimate touring fix (dist ~ 500m in 30s = 60 km/h, altitude is explicitly null)
            {"lat": 32.246, "lng": 77.188, "altitude": None, "speed_kmh": 62.0, "accuracy_m": 12.0, "timestamp": (base_t + timedelta(seconds=35)).isoformat()},
        ]

        filtered, dist_km, elev_m, max_spd, moving_time = filter_gps_points(raw_fixes)

        # Fix 1 and Fix 5 should be accepted. Fixes 2, 3, and 4 must be rejected.
        self.assertEqual(len(filtered), 2)
        self.assertAlmostEqual(filtered[0]["lat"], 32.242)
        self.assertAlmostEqual(filtered[1]["lat"], 32.246)
        self.assertIsNone(filtered[1]["altitude"], "Null altitude must be preserved and not fabricated as 0")
        self.assertGreater(dist_km, 0.4)
        self.assertLess(dist_km, 1.0)
        self.assertLessEqual(max_spd, 220.0)

    def test_privacy_geofence_500m_clipping(self):
        """Verify first and last 500m are stripped to prevent leaking home/hotel locations."""
        # Generate a linear polyline of 12 points, each spaced ~ 150m apart (~ 1.8 km total)
        points = []
        base_t = datetime.now(timezone.utc)
        for i in range(12):
            points.append({
                "lat": 32.240 + (i * 0.0015),
                "lng": 77.185 + (i * 0.0015),
                "altitude": 2000.0 + (i * 20),
                "speed_kmh": 45.0,
                "timestamp": (base_t + timedelta(seconds=i * 10)).isoformat(),
            })

        clipped = clip_privacy_geofence(points, clip_radius_m=500.0)

        # Clipped polyline should have stripped at least the first 2-3 and last 2-3 points
        self.assertLess(len(clipped), len(points))
        # Start point must not match the sensitive home coordinate
        self.assertNotEqual(clipped[0]["lat"], points[0]["lat"])
        # End point must not match the sensitive destination coordinate
        self.assertNotEqual(clipped[-1]["lat"], points[-1]["lat"])

    # ─────────────────────────────────────────────────────────────
    # 2. HAZARD IDEMPOTENCY & PROXIMITY VERIFICATION
    # ─────────────────────────────────────────────────────────────

    @patch("app.api.v1.hazards.get_db")
    def test_hazard_idempotency_duplicate_submission(self, mock_get_db):
        """Verify duplicate hazard submission with same idempotency_key returns existing record."""
        idemp_key = "idemp-key-rohtang-rockfall-99"
        existing_report = HazardReport(
            id=uuid.uuid4(),
            idempotency_key=idemp_key,
            hazard_type=HazardTypeEnum.landslide,
            lifecycle_status=HazardLifecycleEnum.reported,
            severity=SeverityEnum.critical,
            confidence_score=0.95,
            is_active=True,
        )

        mock_session = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalars.return_value.first.return_value = existing_report
        mock_session.execute.return_value = mock_result

        async def _override_get_db():
            yield mock_session

        from app.api.deps import get_db
        app.dependency_overrides[get_db] = _override_get_db

        try:
            payload = {
                "latitude": 32.3712,
                "longitude": 77.2144,
                "hazard_type": "landslide",
                "severity": "critical",
                "idempotency_key": idemp_key,
                "description": "Massive rockfall after blasting on NH3",
            }
            res = self.client.post("/api/v1/hazards/report", json=payload)
            self.assertEqual(res.status_code, 201)
            data = res.json()
            self.assertEqual(data["status"], "existing_idempotent")
            self.assertEqual(data["id"], str(existing_report.id))
        finally:
            app.dependency_overrides.clear()

    @patch("app.api.v1.hazards.get_db")
    def test_anti_spam_proximity_guard_rejection(self, mock_get_db):
        """Verify voter > 5 km away is rejected by Anti-Spam Guard with HTTP 400."""
        hazard_id = uuid.uuid4()
        hazard_report = HazardReport(
            id=hazard_id,
            hazard_type=HazardTypeEnum.black_ice,
            severity=SeverityEnum.high,
            is_active=True,
        )
        fake_geojson = json.dumps({"type": "Point", "coordinates": [77.185, 32.242]})

        mock_session = AsyncMock()
        mock_result = MagicMock()
        mock_result.first.return_value = (hazard_report, fake_geojson)
        mock_session.execute.return_value = mock_result

        async def _override_get_db():
            yield mock_session

        from app.api.deps import get_db
        app.dependency_overrides[get_db] = _override_get_db

        try:
            # Voter located at lat 32.45, lng 77.35 (~ 27 km away)
            verify_payload = {
                "action": "CONFIRM",
                "voter_lat": 32.450,
                "voter_lng": 77.350,
            }
            res = self.client.post(f"/api/v1/hazards/{hazard_id}/verify", json=verify_payload)
            self.assertEqual(res.status_code, 400)
            data = res.json()
            self.assertIn("Anti-Spam Guard", data["detail"])
            self.assertIn("5.0 km", data["detail"])
        finally:
            app.dependency_overrides.clear()

    def test_dynamic_confidence_formula(self):
        """Verify Dynamic Confidence formula accounts for source, evidence, and TTL decay."""
        now = datetime.now(timezone.utc)
        # 1. Fresh BRO official report with photo
        bro_score = compute_hazard_confidence(
            source_type="BRO_POLICE",
            has_photo=True,
            confirmations=5,
            disputes=0,
            created_at=now,
            last_confirmed_at=now,
            ttl_hours=72,
        )
        self.assertGreaterEqual(bro_score, 0.95)

        # 2. Stale report from 40 hours ago with 1 dispute -> decay applied
        stale_time = now - timedelta(hours=40)
        stale_score = compute_hazard_confidence(
            source_type="COMMUNITY",
            has_photo=False,
            confirmations=1,
            disputes=1,
            created_at=stale_time,
            last_confirmed_at=stale_time,
            ttl_hours=48,
        )
        self.assertLess(stale_score, 0.40)
        self.assertGreater(stale_score, 0.05)

    # ─────────────────────────────────────────────────────────────
    # 3. PERSONAL FUEL-RANGE & DRY-ZONE CALCULATOR MATH
    # ─────────────────────────────────────────────────────────────

    async def test_fuel_range_deficit_math_and_disclaimer(self):
        """Verify fuel calculation triggers DEFICIT_WARNING and jerry can advisory on dry zones."""
        # Scenario: Tandi to Karu (365 km dry zone). Current fuel 6.5L, reserve 2.0L.
        req = FuelRangeRequest(
            tank_capacity_l=17.0,
            recent_efficiency_km_l=28.0,
            current_fuel_l=6.5,
            safety_reserve_l=2.0,
            next_pump_distance_km=365.0,
            is_high_altitude=True,  # >3,000m
        )
        res = await calculate_fuel_range(req)

        self.assertEqual(res.status, "DEFICIT_WARNING")
        self.assertLess(res.net_margin_km, 0)
        self.assertIsNotNone(res.deficit_litres_needed)
        self.assertGreater(res.recommended_jerry_can_litres, 0)
        self.assertIn("CRITICAL DEFICIT", res.advisory)
        self.assertIn("jerry can", res.advisory)
        self.assertIn("15–25%", res.disclaimer)

        # Scenario: Short hop (70 km) with full tank (17L) -> SAFE
        req_safe = FuelRangeRequest(
            tank_capacity_l=17.0,
            recent_efficiency_km_l=28.0,
            current_fuel_l=16.0,
            safety_reserve_l=2.0,
            next_pump_distance_km=70.0,
            is_high_altitude=False,
        )
        res_safe = await calculate_fuel_range(req_safe)
        self.assertEqual(res_safe.status, "SAFE")
        self.assertGreater(res_safe.net_margin_km, 200)

    # ─────────────────────────────────────────────────────────────
    # 4. CONVOY OFFLINE SYNC DEDUPLICATION & FRESHNESS
    # ─────────────────────────────────────────────────────────────

    def test_convoy_location_freshness_states(self):
        """Verify honest freshness: LIVE <= 15s, DELAYED 16-90s, OFFLINE > 90s."""
        now = datetime.now(timezone.utc)

        status_live, age_live = evaluate_freshness(now - timedelta(seconds=8))
        self.assertEqual(status_live, "LIVE")
        self.assertLessEqual(age_live, 15.0)

        status_delayed, age_delayed = evaluate_freshness(now - timedelta(seconds=45))
        self.assertEqual(status_delayed, "DELAYED")

        status_offline, age_offline = evaluate_freshness(now - timedelta(seconds=180))
        self.assertEqual(status_offline, "OFFLINE")

        status_unknown, _ = evaluate_freshness(None)
        self.assertEqual(status_unknown, "UNKNOWN")

    def test_offline_batch_sync_deduplication(self):
        """Verify batch sync skips duplicate event IDs using UUID keys."""
        event_1 = uuid.uuid4()
        event_2 = uuid.uuid4()
        now = datetime.now(timezone.utc)

        payload = {
            "ride_room_id": "room-himalayan-squad",
            "points": [
                {
                    "event_id": str(event_1),
                    "rider_id": "rider-me",
                    "rider_name": "Aman",
                    "lat": 32.242,
                    "lng": 77.185,
                    "speed": 65.0,
                    "altitude": 2050.0,
                    "heading": 120.0,
                    "timestamp": now.isoformat(),
                },
                {
                    "event_id": str(event_2),
                    "rider_id": "rider-me",
                    "rider_name": "Aman",
                    "lat": 32.245,
                    "lng": 77.189,
                    "speed": 62.0,
                    "altitude": 2070.0,
                    "heading": 122.0,
                    "timestamp": (now + timedelta(seconds=4)).isoformat(),
                },
            ],
        }

        # First sync submission: both points should be ingested
        res1 = self.client.post("/api/v1/convoy/sync-offline-points", json=payload)
        self.assertEqual(res1.status_code, 200)
        data1 = res1.json()
        self.assertEqual(data1["synced_count"], 2)
        self.assertEqual(data1["duplicates_skipped"], 0)

        # Duplicate sync submission: both points must be skipped
        res2 = self.client.post("/api/v1/convoy/sync-offline-points", json=payload)
        self.assertEqual(res2.status_code, 200)
        data2 = res2.json()
        self.assertEqual(data2["synced_count"], 0)
        self.assertEqual(data2["duplicates_skipped"], 2)

    # ─────────────────────────────────────────────────────────────
    # 7. REAL FILE DOWNLOADS (GPX 1.1 XML & GEOJSON EXPORTS)
    # ─────────────────────────────────────────────────────────────

    def test_gpx_and_geojson_file_download_endpoints(self):
        """Verify real working .gpx and .geojson downloads with valid XML/JSON format."""
        session_id = uuid.uuid4()

        # 1. GPX 1.1 Download
        res_gpx = self.client.get(f"/api/v1/rides/{session_id}/export.gpx")
        self.assertEqual(res_gpx.status_code, 200)
        self.assertIn("application/gpx+xml", res_gpx.headers.get("content-type", ""))
        self.assertIn("attachment; filename=", res_gpx.headers.get("content-disposition", ""))
        self.assertTrue(res_gpx.headers.get("content-disposition", "").endswith('.gpx"'))
        
        gpx_body = res_gpx.text
        self.assertIn('<?xml version="1.0" encoding="UTF-8"?>', gpx_body)
        self.assertIn('<gpx version="1.1"', gpx_body)
        self.assertIn("<trkpt", gpx_body)
        self.assertIn("<ele>", gpx_body)
        self.assertIn("</trkseg>", gpx_body)
        self.assertIn("</trk>", gpx_body)
        self.assertIn("</gpx>", gpx_body)

        # 2. GeoJSON Download
        res_geojson = self.client.get(f"/api/v1/rides/{session_id}/export.geojson")
        self.assertEqual(res_geojson.status_code, 200)
        self.assertIn("application/geo+json", res_geojson.headers.get("content-type", ""))
        self.assertIn("attachment; filename=", res_geojson.headers.get("content-disposition", ""))
        self.assertTrue(res_geojson.headers.get("content-disposition", "").endswith('.geojson"'))

        geo_data = res_geojson.json()
        self.assertEqual(geo_data["type"], "FeatureCollection")
        self.assertGreater(len(geo_data["features"]), 0)
        self.assertEqual(geo_data["features"][0]["geometry"]["type"], "LineString")

    # ─────────────────────────────────────────────────────────────
    # 8. 100% FREE ROUTE COPILOT & INDIAN EXPRESSWAY RESTRICTIONS
    # ─────────────────────────────────────────────────────────────

    def test_free_route_copilot_and_expressway_bans(self):
        """Verify free OSRM + Open-Meteo route copilot and two-wheeler expressway ban detection."""
        # Test Bengaluru to Mysuru (two-wheelers banned on NH-275)
        payload = {
            "start_name": "Bengaluru",
            "start_lat": 12.9716,
            "start_lng": 77.5946,
            "end_name": "Mysuru",
            "end_lat": 12.2958,
            "end_lng": 76.6394,
            "bike_model": "KTM 390 Adventure",
            "bike_cc": 373,
        }
        res = self.client.post("/api/v1/touring-support/route-copilot", json=payload)
        self.assertEqual(res.status_code, 200)
        data = res.json()

        self.assertGreater(data["distance_km"], 100.0)
        self.assertGreater(data["duration_hours"], 1.5)
        self.assertGreater(len(data["coordinates"]), 2)
        self.assertIn("weather_summary", data)
        self.assertIn("black_ice_risk", data["weather_summary"])

        # Must flag Bengaluru-Mysuru Expressway two-wheeler ban
        bans = data["expressway_restrictions"]
        self.assertGreater(len(bans), 0)
        bengaluru_ban = next((b for b in bans if b["corridor_id"] == "bengaluru_mysuru_exp"), None)
        self.assertIsNotNone(bengaluru_ban)
        self.assertEqual(bengaluru_ban["restriction"], "TWO_WHEELERS_BANNED")
        self.assertIn("Old Mysuru Road via SH-17", bengaluru_ban["recommended_alternative"])

    # ─────────────────────────────────────────────────────────────
    # 9. FREE OVERPASS POI QUERY & COMMUNITY STORIES FEED
    # ─────────────────────────────────────────────────────────────

    def test_free_nearby_overpass_poi_query(self):
        """Verify nearby POI discovery querying fuel stations and mechanics with provenance badges."""
        res = self.client.get("/api/v1/touring-support/nearby?lat=32.5539&lng=76.9744&radius_km=30")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "success")
        self.assertGreater(data["count"], 0)
        # Must contain Tandi pump or nearby verified partner
        tandi = next((p for p in data["items"] if "Tandi" in p["name"]), None)
        self.assertIsNotNone(tandi)
        self.assertIn("VERIFIED_PARTNER", tandi["provenance"])

    def test_stories_feed_and_like_counter(self):
        """Verify /stories listing and /stories/{id}/like counter."""
        res = self.client.get("/api/v1/stories")
        self.assertEqual(res.status_code, 200)
        stories = res.json()
        self.assertIsInstance(stories, list)

        # Like endpoint
        dummy_id = uuid.uuid4()
        res_like = self.client.post(f"/api/v1/stories/{dummy_id}/like")
        self.assertEqual(res_like.status_code, 200)
        self.assertIn("likes_count", res_like.json())


if __name__ == "__main__":
    unittest.main()

