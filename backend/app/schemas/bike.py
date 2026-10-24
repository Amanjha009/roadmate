"""Bike and maintenance Pydantic v2 schemas."""

from __future__ import annotations

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.bike import ReminderTypeEnum


# ── Bike ──────────────────────────────────────────────────────────────────────


class BikeCreate(BaseModel):
    model: str = Field(..., max_length=200, examples=["Royal Enfield Himalayan"])
    cc: int = Field(..., ge=50, le=2500)
    year: int = Field(..., ge=1950, le=2100)
    registration_number: str | None = Field(None, max_length=30)
    insurance_expiry: date | None = None
    last_service_date: date | None = None
    next_service_due: date | None = None
    odometer_km: int | None = Field(None, ge=0)
    photo_url: str | None = None


class BikeUpdate(BaseModel):
    model: str | None = Field(None, max_length=200)
    cc: int | None = Field(None, ge=50, le=2500)
    year: int | None = Field(None, ge=1950, le=2100)
    registration_number: str | None = None
    insurance_expiry: date | None = None
    last_service_date: date | None = None
    next_service_due: date | None = None
    odometer_km: int | None = Field(None, ge=0)
    photo_url: str | None = None


class BikeOut(BaseModel):
    id: UUID
    rider_id: UUID
    model: str
    cc: int
    year: int
    registration_number: str | None
    insurance_expiry: date | None
    last_service_date: date | None
    next_service_due: date | None
    odometer_km: int | None
    photo_url: str | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


# ── Maintenance reminders ────────────────────────────────────────────────────


class MaintenanceReminderCreate(BaseModel):
    reminder_type: ReminderTypeEnum
    title: str = Field(..., max_length=200)
    due_date: date
    due_km: int | None = None


class MaintenanceReminderUpdate(BaseModel):
    title: str | None = Field(None, max_length=200)
    due_date: date | None = None
    due_km: int | None = None
    is_completed: bool | None = None


class MaintenanceReminderOut(BaseModel):
    id: UUID
    bike_id: UUID
    reminder_type: ReminderTypeEnum
    title: str
    due_date: date
    due_km: int | None
    is_completed: bool
    completed_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}
