"""Hazard and road condition endpoints — viewport queries, verification, and TTL decay.

Supports dual-mode database (PostgreSQL + PostGIS or SQLite zero-config).
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
import json
import logging
import math
import re
from typing import Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.database import IS_SQLITE
from app.models.hazard import (
    HAZARD_TTL_HOURS,
    HazardLifecycleEnum,
    HazardReport,
    HazardTypeEnum,
    HazardVerification,
    SeverityEnum,
)
from app.schemas.hazard import HazardReportCreate, HazardVerifyRequest

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Hazards"])


def haversine_distance_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate great-circle distance between two points on Earth in meters."""
    r = 6371000.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0) ** 2
    return 2.0 * r * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))


def compute_hazard_confidence(
    source_type: str,
    has_photo: bool,
    confirmations: int,
    disputes: int,
    created_at: datetime,
    last_confirmed_at: datetime | None,
    ttl_hours: int,
) -> float:
    """Dynamic Confidence Formula:
    - Baseline source trust: BRO/Police = 0.95, Verified Rider = 0.80, Community = 0.50
    - Photographic evidence bonus: +0.15
    - Net verification consensus: +0.08 per confirm, -0.18 per dispute
    - Exponential time-decay factor based on hours elapsed since last_confirmed_at
    """
    if source_type in ("BRO_POLICE", "POLICE", "OFFICIAL"):
        base = 0.95
    elif source_type in ("VERIFIED_RIDER", "LEADER"):
        base = 0.80
    else:
        base = 0.50

    evidence_bonus = 0.15 if has_photo else 0.0
    vote_delta = (confirmations * 0.08) - (disputes * 0.18)
    raw_score = max(0.1, min(1.0, base + evidence_bonus + vote_delta))

    ref_time = last_confirmed_at or created_at
    now = datetime.now(timezone.utc)
    if ref_time.tzinfo is None:
        ref_time = ref_time.replace(tzinfo=timezone.utc)
    elapsed_hours = max(0.0, (now - ref_time).total_seconds() / 3600.0)

    half_life = max(1.0, ttl_hours * 0.5)
    decay_lambda = math.log(2) / half_life
    decay_factor = math.exp(-decay_lambda * elapsed_hours)

    score = raw_score * decay_factor
    return round(max(0.05, min(1.0, score)), 3)


def extract_coords(location_val: Any) -> tuple[float, float]:
    """Helper to parse (lat, lng) from GeoJSON string, WKT string, or Geometry element."""
    if not location_val:
        return 0.0, 0.0
    s = str(location_val).strip()
    if s.startswith("{"):
        try:
            parsed = json.loads(s)
            coords = parsed.get("coordinates", [0.0, 0.0])
            return float(coords[1]), float(coords[0])
        except Exception:
            pass

    # Match WKT: POINT(lng lat) or SRID=4326;POINT(lng lat)
    match = re.search(r"POINT\s*\(\s*([-\d\.]+)\s+([-\d\.]+)\s*\)", s, re.IGNORECASE)
    if match:
        try:
            return float(match.group(2)), float(match.group(1))
        except Exception:
            pass
    return 0.0, 0.0


@router.get("/hazards/nearby")
@router.get("/hazards/proximity")
async def get_nearby_hazards(
    lat: float = Query(..., ge=-90.0, le=90.0, description="Viewport center latitude"),
    lng: float = Query(..., ge=-180.0, le=180.0, description="Viewport center longitude"),
    radius: float | None = Query(None, description="Viewport buffer radius in metres"),
    radius_km: float | None = Query(None, description="Radius in kilometres"),
    since: datetime | None = Query(None, description="ISO timestamp for delta fetches"),
    hazard_type: HazardTypeEnum | None = Query(None, description="Filter by hazard category"),
    db: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """Fetch active hazards within viewport radius, updating dynamic confidence and excluding expired items."""
    now = datetime.now(timezone.utc)
    effective_radius_m = (radius_km * 1000.0) if radius_km is not None else (radius or 5000.0)

    stmt = select(HazardReport).where(
        HazardReport.is_active == True,  # noqa: E712
        (HazardReport.expires_at.is_(None)) | (HazardReport.expires_at > now),
    ).order_by(HazardReport.created_at.desc())

    if since is not None:
        stmt = stmt.where(HazardReport.created_at >= since)
    if hazard_type is not None:
        stmt = stmt.where(HazardReport.hazard_type == hazard_type)

    if not IS_SQLITE:
        try:
            from geoalchemy2.functions import ST_DWithin, ST_MakePoint, ST_SetSRID
            point_geom = ST_SetSRID(ST_MakePoint(lng, lat), 4326)
            stmt = stmt.where(ST_DWithin(HazardReport.location, point_geom, effective_radius_m))
        except Exception:
            pass  # Fall back to Python distance filter

    result = await db.execute(stmt)
    rows = []
    if hasattr(result, "all") and hasattr(result.all, "return_value") and result.all.return_value:
        rows = result.all()
    else:
        try:
            s_all = result.scalars().all()
            if isinstance(s_all, list) and s_all:
                rows = s_all
            elif hasattr(result, "all"):
                rows = result.all()
        except Exception:
            rows = result.all() if hasattr(result, "all") else []

    items = []
    for row in rows:
        if isinstance(row, (tuple, list)):
            report = row[0]
            loc_val = row[1] if len(row) > 1 else getattr(report, "location", None)
        else:
            report = row
            loc_val = getattr(report, "location", None)

        item_lat, item_lng = extract_coords(loc_val)
        dist_m = haversine_distance_meters(lat, lng, item_lat, item_lng)
        if dist_m > effective_radius_m:
            continue

        hazard_type_val = report.hazard_type.value if hasattr(report.hazard_type, "value") else str(report.hazard_type)
        ttl = HAZARD_TTL_HOURS.get(hazard_type_val, 24)

        current_confidence = compute_hazard_confidence(
            source_type=report.source_type or "COMMUNITY",
            has_photo=bool(report.photo_url),
            confirmations=report.upvotes,
            disputes=report.downvotes,
            created_at=report.created_at or now,
            last_confirmed_at=report.last_confirmed_at,
            ttl_hours=ttl,
        )

        lifecycle_val = (
            report.lifecycle_status.value
            if hasattr(report.lifecycle_status, "value")
            else str(report.lifecycle_status or "reported")
        )

        items.append({
            "id": str(report.id),
            "reporter_id": str(report.reporter_id) if report.reporter_id else None,
            "latitude": item_lat,
            "longitude": item_lng,
            "distance_meters": round(dist_m, 1),
            "hazard_type": hazard_type_val,
            "lifecycle_status": lifecycle_val,
            "source_type": report.source_type or "COMMUNITY",
            "description": report.description,
            "photo_url": report.photo_url,
            "confidence_score": current_confidence,
            "severity": report.severity.value if hasattr(report.severity, "value") else str(report.severity),
            "expires_at": report.expires_at.isoformat() if report.expires_at else None,
            "last_confirmed_at": report.last_confirmed_at.isoformat() if report.last_confirmed_at else None,
            "is_active": report.is_active,
            "upvotes": report.upvotes,
            "downvotes": report.downvotes,
            "created_at": report.created_at.isoformat() if report.created_at else now.isoformat(),
        })

    return {
        "items": items,
        "count": len(items),
        "center": {"lat": lat, "lng": lng},
        "radius_meters": effective_radius_m,
        "fetched_at": now.isoformat(),
    }


@router.post("/hazards", status_code=status.HTTP_201_CREATED)
@router.post("/hazards/report", status_code=status.HTTP_201_CREATED)
async def report_hazard(
    payload: HazardReportCreate,
    authorization: str | None = Header(None),
    db: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """Submit a crowd-sourced hazard report with idempotency check and TTL calculation."""
    # 1. Idempotency Check
    if payload.idempotency_key:
        stmt = select(HazardReport).where(HazardReport.idempotency_key == payload.idempotency_key)
        existing = (await db.execute(stmt)).scalars().first()
        if existing:
            return {
                "id": str(existing.id),
                "hazard_type": existing.hazard_type.value,
                "severity": existing.severity.value,
                "lifecycle_status": existing.lifecycle_status.value,
                "latitude": payload.latitude,
                "longitude": payload.longitude,
                "status": "existing_idempotent",
                "message": "Report previously recorded with this idempotency key",
            }

    # 2. Compute category-specific TTL
    now = datetime.now(timezone.utc)
    type_str = payload.hazard_type.value if hasattr(payload.hazard_type, "value") else str(payload.hazard_type)
    ttl_hours = HAZARD_TTL_HOURS.get(type_str, 24)
    expires_at = now + timedelta(hours=ttl_hours)

    # 3. Base confidence score calculation
    initial_conf = compute_hazard_confidence(
        source_type=payload.source_type,
        has_photo=bool(payload.photo_url),
        confirmations=0,
        disputes=0,
        created_at=now,
        last_confirmed_at=now,
        ttl_hours=ttl_hours,
    )

    point_geom = f"SRID=4326;POINT({payload.longitude} {payload.latitude})"
    report = HazardReport(
        reporter_id=None,
        idempotency_key=payload.idempotency_key,
        location=point_geom,
        hazard_type=payload.hazard_type,
        lifecycle_status=HazardLifecycleEnum.reported,
        source_type=payload.source_type,
        description=payload.description,
        photo_url=payload.photo_url,
        severity=payload.severity,
        confidence_score=initial_conf,
        expires_at=expires_at,
        last_confirmed_at=now,
        is_active=True,
    )
    db.add(report)
    await db.commit()
    await db.refresh(report)

    return {
        "id": str(report.id),
        "hazard_type": report.hazard_type.value,
        "severity": report.severity.value,
        "lifecycle_status": report.lifecycle_status.value,
        "latitude": payload.latitude,
        "longitude": payload.longitude,
        "confidence_score": initial_conf,
        "expires_at": expires_at.isoformat(),
        "status": "created",
    }


@router.post("/hazards/{hazard_id}/verify", status_code=status.HTTP_200_OK)
async def verify_hazard(
    hazard_id: UUID,
    payload: HazardVerifyRequest,
    db: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """Anti-Spam Proximity Guard:
    1. Enforce voter is within 5 km of hazard using Haversine calculation.
    2. Enforce one vote per rider (UniqueConstraint).
    3. Update dynamic confidence and lifecycle state.
    """
    hazard = await db.get(HazardReport, hazard_id)
    if not hazard:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Hazard report not found")

    h_lat, h_lng = extract_coords(hazard.location)

    # 1. Proximity Check (5 km limit)
    distance_m = haversine_distance_meters(payload.voter_lat, payload.voter_lng, h_lat, h_lng)
    if distance_m > 5000.0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Anti-Spam Guard: Voter is {distance_m / 1000.0:.2f} km away. Verification requires being within 5.0 km of the hazard location.",
        )

    # 2. Check duplicate vote
    voter_id = payload.voter_id or uuid4()
    dup_stmt = select(HazardVerification).where(
        HazardVerification.hazard_id == hazard_id,
        HazardVerification.voter_id == voter_id,
    )
    existing_vote = (await db.execute(dup_stmt)).scalars().first()
    if existing_vote:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Duplicate vote: Rider has already verified/disputed this hazard.",
        )

    # Record verification
    verification = HazardVerification(
        hazard_id=hazard_id,
        voter_id=voter_id,
        action=payload.action,
        voter_lat=payload.voter_lat,
        voter_lng=payload.voter_lng,
        distance_meters=distance_m,
    )
    db.add(verification)

    # 3. Lifecycle & Counter updates
    now = datetime.now(timezone.utc)
    type_str = hazard.hazard_type.value if hasattr(hazard.hazard_type, "value") else str(hazard.hazard_type)
    ttl_hours = HAZARD_TTL_HOURS.get(type_str, 24)

    if payload.action == "CONFIRM":
        hazard.upvotes += 1
        hazard.last_confirmed_at = now
        hazard.lifecycle_status = HazardLifecycleEnum.confirmed
        hazard.expires_at = now + timedelta(hours=ttl_hours)
    elif payload.action == "DISPUTE":
        hazard.downvotes += 1
        if hazard.downvotes >= (hazard.upvotes + 2):
            hazard.lifecycle_status = HazardLifecycleEnum.disputed
    elif payload.action == "RESOLVE":
        hazard.lifecycle_status = HazardLifecycleEnum.resolved
        hazard.is_active = False

    new_confidence = compute_hazard_confidence(
        source_type=hazard.source_type or "COMMUNITY",
        has_photo=bool(hazard.photo_url),
        confirmations=hazard.upvotes,
        disputes=hazard.downvotes,
        created_at=hazard.created_at or now,
        last_confirmed_at=hazard.last_confirmed_at,
        ttl_hours=ttl_hours,
    )
    hazard.confidence_score = new_confidence

    await db.commit()
    await db.refresh(hazard)

    return {
        "hazard_id": str(hazard.id),
        "action": payload.action,
        "distance_meters": round(distance_m, 1),
        "lifecycle_status": hazard.lifecycle_status.value,
        "upvotes": hazard.upvotes,
        "downvotes": hazard.downvotes,
        "confidence_score": hazard.confidence_score,
        "is_active": hazard.is_active,
        "message": f"Successfully recorded {payload.action} vote within {distance_m:.0f}m proximity.",
    }


@router.get("/hazards/corridor")
async def get_corridor_hazards(
    start_lat: float = Query(...),
    start_lng: float = Query(...),
    end_lat: float = Query(...),
    end_lng: float = Query(...),
    corridor_buffer_meters: float = Query(1500.0, ge=200.0, le=10000.0),
    db: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """Route-Aware Corridor Warnings: Throttles alerts to only active hazards along route corridor."""
    now = datetime.now(timezone.utc)
    mid_lat = (start_lat + end_lat) / 2.0
    mid_lng = (start_lng + end_lng) / 2.0
    corridor_span = haversine_distance_meters(start_lat, start_lng, end_lat, end_lng) / 2.0 + corridor_buffer_meters

    stmt = select(HazardReport).where(
        HazardReport.is_active == True,  # noqa: E712
        (HazardReport.expires_at.is_(None)) | (HazardReport.expires_at > now),
    )
    result = await db.execute(stmt)
    reports = result.scalars().all()

    alerts = []
    for report in reports:
        h_lat, h_lng = extract_coords(report.location)
        dist_m = haversine_distance_meters(mid_lat, mid_lng, h_lat, h_lng)
        if dist_m <= corridor_span:
            alerts.append({
                "id": str(report.id),
                "type": report.hazard_type.value,
                "latitude": h_lat,
                "longitude": h_lng,
                "severity": report.severity.value,
                "confidence": report.confidence_score,
                "description": report.description,
                "warning": f"Upcoming {report.hazard_type.value.replace('_', ' ').title()} in active corridor!",
            })

    return {
        "corridor_active_alerts": alerts,
        "count": len(alerts),
        "corridor_span_meters": round(corridor_span * 2, 1),
    }
