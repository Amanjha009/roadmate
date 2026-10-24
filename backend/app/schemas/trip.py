"""Trip planning Pydantic v2 schemas."""

from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.trip import ExperienceLevelEnum, TripStatusEnum


class TripPlanRequest(BaseModel):
    """Request body for ``POST /trips/plan``."""

    title: str = Field(..., max_length=300)
    origin: str = Field(..., max_length=300, examples=["Delhi"])
    destination: str = Field(..., max_length=300, examples=["Leh"])
    bike_id: UUID | None = None
    departure_date: datetime
    experience_level: ExperienceLevelEnum
    preferences: dict[str, Any] | None = Field(
        None,
        examples=[{"avoid_highways": True, "scenic_route": True, "night_riding": False}],
    )


class TripOut(BaseModel):
    id: UUID
    rider_id: UUID
    title: str
    origin: str
    destination: str
    bike_id: UUID | None
    departure_date: datetime
    experience_level: ExperienceLevelEnum
    preferences: dict[str, Any] | None
    route_data: dict[str, Any] | None
    status: TripStatusEnum
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
