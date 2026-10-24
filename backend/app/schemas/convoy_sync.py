"""Pydantic v2 schemas for Offline Convoy Sync and Location Freshness."""

from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


class OfflineTelemetryPoint(BaseModel):
    """A locally queued telemetry fix captured while offline."""

    event_id: UUID = Field(..., description="Unique UUID event key generated on device to reject duplicates")
    rider_id: str = Field(..., description="Unique rider identifier")
    rider_name: str = Field(..., description="Display name of rider")
    lat: float = Field(..., ge=-90.0, le=90.0)
    lng: float = Field(..., ge=-180.0, le=180.0)
    speed: float = Field(0.0, ge=0.0)
    altitude: float | None = None
    heading: float = Field(0.0, ge=0.0, le=360.0)
    timestamp: datetime = Field(..., description="Timestamp when point was recorded locally")


class BatchSyncRequest(BaseModel):
    """Batch payload submitted when mobile device transitions from offline to online."""

    ride_room_id: str = Field(..., description="Target convoy ride room")
    points: list[OfflineTelemetryPoint] = Field(..., max_length=5000)


class BatchSyncResponse(BaseModel):
    synced_count: int
    duplicates_skipped: int
    latest_timestamp: datetime | None
    status: Literal["ok", "partial", "rejected"]
    message: str


class ConvoyFreshnessStatus(BaseModel):
    rider_id: str
    rider_name: str
    status: Literal["LIVE", "DELAYED", "OFFLINE", "UNKNOWN"]
    age_seconds: float | None
    last_known_lat: float | None
    last_known_lng: float | None
    last_seen: datetime | None
