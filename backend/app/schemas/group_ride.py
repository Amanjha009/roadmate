"""Group ride Pydantic v2 schemas."""

from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.group_ride import (
    GroupRideStatusEnum,
    MemberRoleEnum,
    MemberStatusEnum,
)
from app.models.trip import ExperienceLevelEnum


class GroupRideCreate(BaseModel):
    title: str = Field(..., max_length=300)
    description: str | None = None
    trip_id: UUID | None = None
    route_summary: str
    required_gear: list[str] | None = None
    max_riders: int = Field(..., ge=2, le=200)
    min_experience: ExperienceLevelEnum = ExperienceLevelEnum.beginner
    min_verification_level: int = Field(1, ge=1, le=3)
    is_women_only: bool = False
    start_time: datetime


class GroupRideUpdate(BaseModel):
    title: str | None = Field(None, max_length=300)
    description: str | None = None
    route_summary: str | None = None
    required_gear: list[str] | None = None
    max_riders: int | None = Field(None, ge=2, le=200)
    min_experience: ExperienceLevelEnum | None = None
    min_verification_level: int | None = Field(None, ge=1, le=3)
    is_women_only: bool | None = None
    status: GroupRideStatusEnum | None = None
    start_time: datetime | None = None


class GroupRideMemberOut(BaseModel):
    id: UUID
    rider_id: UUID
    role: MemberRoleEnum
    status: MemberStatusEnum
    last_lat: float | None
    last_lng: float | None
    last_location_at: datetime | None
    joined_at: datetime

    model_config = {"from_attributes": True}


class GroupRideOut(BaseModel):
    id: UUID
    captain_id: UUID
    title: str
    description: str | None
    join_code: str | None = None
    trip_id: UUID | None
    route_summary: str
    required_gear: list[str] | None
    max_riders: int
    min_experience: ExperienceLevelEnum
    min_verification_level: int
    is_women_only: bool
    status: GroupRideStatusEnum
    start_time: datetime
    created_at: datetime
    updated_at: datetime
    members: list[GroupRideMemberOut] = []

    model_config = {"from_attributes": True}


class CreateTripGroupRequest(BaseModel):
    """Request to create a personal trip group and generate a shareable join code."""
    title: str = Field(..., max_length=150, description="Name of the trip group")
    route_summary: str = Field(..., description="Route or starting point to destination")
    destination: str | None = Field(None, description="Trip destination")
    max_riders: int = Field(12, ge=2, le=100)
    captain_name: str = Field("Aman Jha", description="Name of the group creator / Road Captain")
    captain_bike: str = Field("Royal Enfield Himalayan 450", description="Captain's motorcycle model")
    is_women_only: bool = False


class JoinTripGroupRequest(BaseModel):
    """Request from an individual rider to join an existing trip group using the code."""
    join_code: str = Field(..., max_length=20, description="The unique 6-character group code")
    rider_name: str = Field("Rider", max_length=100, description="Name of joining rider")
    bike_model: str = Field("Motorcycle", max_length=100, description="Motorcycle make and model")
    role: MemberRoleEnum = Field(MemberRoleEnum.member, description="Desired role: member or sweep")


class GroupRideSessionOut(BaseModel):
    """Full session details for a live or planned trip group."""
    group_id: str
    join_code: str
    title: str
    route_summary: str
    destination: str | None = None
    captain_name: str
    captain_bike: str | None = None
    status: str = "live"
    max_riders: int = 12
    created_at: str
    members_count: int
    members: list[dict[str, Any]] = []
    websocket_room_id: str
    websocket_url: str
    share_text: str


class SoloRideSessionOut(BaseModel):
    """Session details when traveling in Solo Mode."""
    session_id: str
    mode: str = "solo"
    rider_name: str
    bike_model: str
    route_title: str
    started_at: str
    is_hazard_radar_active: bool = True
    is_crash_detection_active: bool = True
    is_voice_sos_active: bool = True
    tracking_share_url: str
    offline_sync_ready: bool = True


class LocationUpdate(BaseModel):
    """Live position update from a member."""

    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

