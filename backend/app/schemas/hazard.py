"""Hazard report Pydantic v2 schemas with Indian geospatial bounds & verification guardrails."""

from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field, field_validator

from app.models.hazard import HazardLifecycleEnum, HazardTypeEnum, SeverityEnum


class HazardReportCreate(BaseModel):
    """Request body for creating a hazard report with Indian coordinate validation and idempotency."""

    latitude: float = Field(..., ge=6.0, le=38.0, description="Indian latitude range [6.0, 38.0]")
    longitude: float = Field(..., ge=68.0, le=98.0, description="Indian longitude range [68.0, 98.0]")
    hazard_type: HazardTypeEnum
    description: str | None = Field(None, min_length=3, max_length=500)
    photo_url: str | None = None
    severity: SeverityEnum = SeverityEnum.medium
    idempotency_key: str | None = Field(None, max_length=128, description="Client idempotency key")
    source_type: str = Field("COMMUNITY", description="BRO_POLICE, VERIFIED_RIDER, COMMUNITY")

    @field_validator("idempotency_key")
    @classmethod
    def validate_idempotency(cls, v: str | None) -> str | None:
        if v is not None and not v.strip():
            return None
        return v


class HazardVerifyRequest(BaseModel):
    """Voter verification request with 5km proximity check."""

    action: Literal["CONFIRM", "DISPUTE", "RESOLVE"] = Field(..., description="Vote action")
    voter_lat: float = Field(..., ge=6.0, le=38.0, description="Current rider latitude")
    voter_lng: float = Field(..., ge=68.0, le=98.0, description="Current rider longitude")
    voter_id: UUID | None = Field(None, description="Optional voter UUID override for demo/test")


class HazardReportOut(BaseModel):
    id: UUID
    reporter_id: UUID | None
    latitude: float
    longitude: float
    hazard_type: HazardTypeEnum
    lifecycle_status: HazardLifecycleEnum
    source_type: str
    description: str | None
    photo_url: str | None
    confidence_score: float
    severity: SeverityEnum
    expires_at: datetime | None
    last_confirmed_at: datetime | None
    is_active: bool
    upvotes: int
    downvotes: int
    created_at: datetime

    model_config = {"from_attributes": True}


class NearbyHazardQuery(BaseModel):
    """Query parameters for nearby hazard search."""

    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)
    radius: float = Field(5000.0, ge=100, le=50000, description="Radius in metres")
