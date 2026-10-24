"""Rider profile Pydantic v2 schemas."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.rider import GenderEnum


class RiderOut(BaseModel):
    """Public rider profile representation."""

    id: UUID
    phone: str
    name: str | None = None
    avatar_url: str | None = None
    gender: GenderEnum | None = None
    verification_level: int
    trust_score: float
    is_women_circle_eligible: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class RiderUpdate(BaseModel):
    """Fields a rider may update on their own profile."""

    name: str | None = Field(None, max_length=120)
    avatar_url: str | None = None
    gender: GenderEnum | None = None


class TrustScoreOut(BaseModel):
    rider_id: UUID
    trust_score: float


class EmergencyContactOut(BaseModel):
    id: UUID
    name: str
    phone: str
    relationship: str
    is_primary: bool
    priority: int = 1
    telegram_chat_id: str | None = None

    model_config = {"from_attributes": True}


class EmergencyContactCreate(BaseModel):
    name: str = Field(..., max_length=120)
    phone: str = Field(..., max_length=20)
    relationship: str = Field(..., max_length=60)
    is_primary: bool = False
    priority: int = Field(default=1, ge=1, le=10, description="Priority dispatch order (1 = highest)")
    telegram_chat_id: str | None = Field(default=None, max_length=50)
