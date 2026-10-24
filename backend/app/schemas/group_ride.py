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


class LocationUpdate(BaseModel):
    """Live position update from a member."""

    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
