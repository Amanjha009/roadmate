"""Smart Convoy Safety & Offline Batch Sync API.

Features:
- Honest Connectivity & Location Freshness model:
  LIVE (<= 15s), DELAYED (16s–90s), OFFLINE (> 90s), UNKNOWN
- Offline SQLite/local points sync via POST /api/v1/convoy/sync-offline-points with UUID deduplication
- Hysteresis Separation Detection: trigger at >=1,500m for 45s, clear at <1,100m, 180s cooldown
- 1-tap check-ins: "Request Regroup" and "I'm OK / Stopping for Photo"
"""

from __future__ import annotations

from datetime import datetime, timezone
import math
from typing import Any
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status

from app.schemas.convoy_sync import (
    BatchSyncRequest,
    BatchSyncResponse,
    ConvoyFreshnessStatus,
)
from app.services.redis_pubsub import ride_pubsub

router = APIRouter(prefix="/convoy", tags=["Convoy Sync & Safety"])

# In-memory store for ingested event IDs (deduplication cache)
_INGESTED_EVENT_IDS: set[str] = set()

# In-memory state for convoy riders and separation monitor
_CONVOY_MEMBERS_STATE: dict[str, dict[str, Any]] = {}
_LAST_SEPARATION_ALERT_TIME: dict[str, datetime] = {}
_SEPARATION_START_TIME: dict[str, datetime] = {}


def haversine_dist_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371000.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0) ** 2
    return 2.0 * r * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))


def evaluate_freshness(timestamp: datetime | None) -> tuple[str, float | None]:
    """Evaluates freshness strictly against physical time elapsed:
    - LIVE: <= 15s ago
    - DELAYED: 16s - 90s ago
    - OFFLINE: > 90s ago
    - UNKNOWN: no timestamp
    """
    if timestamp is None:
        return "UNKNOWN", None

    now = datetime.now(timezone.utc)
    if timestamp.tzinfo is None:
        timestamp = timestamp.replace(tzinfo=timezone.utc)

    age_s = max(0.0, (now - timestamp).total_seconds())
    if age_s <= 15.0:
        return "LIVE", round(age_s, 1)
    elif age_s <= 90.0:
        return "DELAYED", round(age_s, 1)
    else:
        return "OFFLINE", round(age_s, 1)


@router.post("/sync-offline-points", response_model=BatchSyncResponse)
async def sync_offline_points(payload: BatchSyncRequest) -> Any:
    """Batch-sync locally queued GPS points upon reconnecting with duplicate rejection."""
    synced_count = 0
    duplicates_skipped = 0
    latest_ts: datetime | None = None

    for pt in payload.points:
        key = str(pt.event_id)
        if key in _INGESTED_EVENT_IDS:
            duplicates_skipped += 1
            continue

        _INGESTED_EVENT_IDS.add(key)
        synced_count += 1

        if latest_ts is None or pt.timestamp > latest_ts:
            latest_ts = pt.timestamp

        # Update latest known member state in convoy
        _CONVOY_MEMBERS_STATE[pt.rider_id] = {
            "rider_id": pt.rider_id,
            "rider_name": pt.rider_name,
            "lat": pt.lat,
            "lng": pt.lng,
            "speed": pt.speed,
            "altitude": pt.altitude,
            "heading": pt.heading,
            "timestamp": pt.timestamp,
        }

    # Fan out sync completion notification over room pubsub
    channel = f"ride_room:{payload.ride_room_id}"
    await ride_pubsub.publish(
        channel,
        {
            "type": "offline_batch_synced",
            "synced_count": synced_count,
            "duplicates_skipped": duplicates_skipped,
            "latest_timestamp": latest_ts.isoformat() if latest_ts else None,
        },
    )

    return BatchSyncResponse(
        synced_count=synced_count,
        duplicates_skipped=duplicates_skipped,
        latest_timestamp=latest_ts,
        status="ok",
        message=f"Synced {synced_count} offline fixes ({duplicates_skipped} duplicates rejected).",
    )


@router.get("/freshness/{ride_room_id}", response_model=list[ConvoyFreshnessStatus])
async def get_convoy_freshness(ride_room_id: str) -> Any:
    """Query location freshness status for all convoy riders."""
    statuses = []
    now = datetime.now(timezone.utc)

    # If empty, provide realistic demo squad
    demo_members = _CONVOY_MEMBERS_STATE if _CONVOY_MEMBERS_STATE else {
        "rider-vikram": {
            "rider_id": "rider-vikram",
            "rider_name": "Vikram (Lead)",
            "lat": 32.242,
            "lng": 77.185,
            "timestamp": now,
        },
        "rider-priya": {
            "rider_id": "rider-priya",
            "rider_name": "Priya (Scout)",
            "lat": 32.251,
            "lng": 77.192,
            "timestamp": now,
        },
        "rider-arjun": {
            "rider_id": "rider-arjun",
            "rider_name": "Arjun",
            "lat": 32.228,
            "lng": 77.170,
            "timestamp": now,
        },
    }

    for rid, data in demo_members.items():
        ts = data.get("timestamp")
        freshness_label, age_seconds = evaluate_freshness(ts)
        statuses.append(
            ConvoyFreshnessStatus(
                rider_id=data["rider_id"],
                rider_name=data["rider_name"],
                status=freshness_label,  # type: ignore
                age_seconds=age_seconds,
                last_known_lat=data.get("lat"),
                last_known_lng=data.get("lng"),
                last_seen=ts,
            )
        )

    return statuses


@router.post("/separation-check/{ride_room_id}")
async def check_convoy_separation(
    ride_room_id: str,
    rider_lat: float = Query(...),
    rider_lng: float = Query(...),
    lead_lat: float = Query(...),
    lead_lng: float = Query(...),
) -> dict[str, Any]:
    """Hysteresis Separation Evaluation:
    - Trigger threshold: separation >= 1,500m sustained for 45s
    - Clear threshold: separation < 1,100m
    - Alert cooldown: 180s
    """
    now = datetime.now(timezone.utc)
    dist_m = haversine_dist_meters(rider_lat, rider_lng, lead_lat, lead_lng)

    alert_active = False
    message = "Convoy pack within normal touring separation."

    start_t = _SEPARATION_START_TIME.get(ride_room_id)
    last_alert_t = _LAST_SEPARATION_ALERT_TIME.get(ride_room_id)

    if dist_m >= 1500.0:
        if start_t is None:
            _SEPARATION_START_TIME[ride_room_id] = now
            sustained_s = 0.0
        else:
            sustained_s = (now - start_t).total_seconds()

        if sustained_s >= 45.0:
            # Check cooldown (180s)
            can_alert = True
            if last_alert_t and (now - last_alert_t).total_seconds() < 180.0:
                can_alert = False

            if can_alert:
                alert_active = True
                _LAST_SEPARATION_ALERT_TIME[ride_room_id] = now
                message = f"Pack separation > 1.5 km ({dist_m/1000.0:.2f} km) sustained for {sustained_s:.0f}s — Suggest Convoy Check-In."
    elif dist_m < 1100.0:
        # Clear hysteresis
        _SEPARATION_START_TIME.pop(ride_room_id, None)
        alert_active = False
        message = f"Convoy regrouped. Current separation: {dist_m:.0f}m."

    return {
        "separation_meters": round(dist_m, 1),
        "alert_active": alert_active,
        "message": message,
        "trigger_threshold_m": 1500.0,
        "clear_threshold_m": 1100.0,
    }


@router.post("/checkin/{ride_room_id}")
async def broadcast_checkin(
    ride_room_id: str,
    rider_name: str = Query("Rider"),
    status_type: str = Query("IM_OK", description="IM_OK or REGROUP_REQUEST"),
    note: str | None = Query(None),
) -> dict[str, Any]:
    """Broadcast 1-tap 'Request Regroup' or 'I'm OK / Stopping for Photo'."""
    text = (
        f"📸 {rider_name}: I'm OK / Stopping for Photo ({note or 'Quick break'})"
        if status_type == "IM_OK"
        else f"⚠️ {rider_name}: Requested Squad Regroup at next safe pullout!"
    )

    channel = f"ride_room:{ride_room_id}"
    await ride_pubsub.publish(
        channel,
        {
            "type": "convoy_checkin",
            "rider_name": rider_name,
            "status_type": status_type,
            "message": text,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        },
    )

    return {"status": "broadcasted", "message": text}
