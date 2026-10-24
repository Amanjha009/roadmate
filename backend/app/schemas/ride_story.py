"""Pydantic v2 schemas for RideStory and Ride Recording Lifecycle."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.ride_story import RecordingStateEnum, StoryThemeEnum, StoryVisibilityEnum


class GPSPointInput(BaseModel):
    """Raw GPS point from mobile/simulator with accuracy and velocity."""

    lat: float = Field(..., ge=-90.0, le=90.0)
    lng: float = Field(..., ge=-180.0, le=180.0)
    altitude: float | None = Field(None, description="Distinguish null (unavailable) from 0")
    speed_kmh: float = Field(0.0, ge=0.0)
    accuracy_m: float = Field(..., ge=0.0, description="Horizontal accuracy in meters")
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class SessionStartRequest(BaseModel):
    title: str = Field("Himalayan High Pass Run", max_length=140)


class SessionActionResponse(BaseModel):
    session_id: UUID
    rider_id: UUID
    state: RecordingStateEnum
    message: str
    points_ingested: int
    started_at: datetime
    finished_at: datetime | None = None


class StoryCreateRequest(BaseModel):
    session_id: UUID | None = None
    title: str = Field("Manali to Keylong Expedition", max_length=140)
    theme: StoryThemeEnum = StoryThemeEnum.mountain_escape
    visibility: StoryVisibilityEnum = StoryVisibilityEnum.public
    privacy_clipped: bool = Field(True, description="Clip 500m start/end geofence")
    hide_max_speed: bool = Field(True, description="Safe Speed Policy — hide max speed publicly")
    start_region: str = Field("Manali 2,050m", max_length=100)
    end_region: str = Field("Keylong 3,080m", max_length=100)
    raw_points: list[GPSPointInput] | None = None


class StoryOut(BaseModel):
    id: UUID
    session_id: UUID | None
    rider_id: UUID
    title: str
    theme: str
    visibility: str
    start_region: str
    end_region: str
    start_altitude_m: float | None
    end_altitude_m: float | None
    total_distance_km: float
    moving_time_seconds: int
    elapsed_time_seconds: int
    elevation_gain_meters: float
    max_speed_kmh: float | None
    hide_max_speed: bool
    privacy_clipped: bool
    achievements: list[str]
    route_polyline: list[dict[str, Any]]
    likes_count: int = 12
    bookmarks_count: int = 4
    created_at: datetime

    model_config = {"from_attributes": True}
