"""Pydantic v2 schemas for SOS emergency triggers, escalation, and audio context."""

from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.sos import SOSStatusEnum, SOSTriggerTypeEnum


class SOSTriggerRequest(BaseModel):
    """Payload sent by mobile client immediately when voice or crash trigger fires.
    
    This initiates parallel GPS capture and emergency contact queueing on the server
    without waiting for the local 10-second cancel window.
    """

    trigger_type: SOSTriggerTypeEnum = Field(
        ...,
        description="Source of emergency trigger: 'voice' | 'crash_detected' | 'manual'",
    )
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    location_trail: list[dict[str, Any]] | None = Field(
        default=None,
        description="Breadcrumb trail of recent coordinates leading up to incident",
    )
    group_ride_id: UUID | None = None
    trigger_phrase: str | None = Field(
        default=None,
        description="Wake phrase detected (e.g. 'Hey RoadMate, I need help')",
    )
    g_force_peak: float | None = Field(
        default=None,
        description="Peak impact G-force if triggered via crash motion sensor",
    )
    audio_clip_url: str | None = Field(
        default=None,
        description="URL of short encrypted ambient audio clip if already uploaded",
    )
    is_unresponsive: bool = Field(
        default=False,
        description="True if 10-second vocal/physical responsiveness check timed out with no response",
    )


class SOSConfirmRequest(BaseModel):
    """Sent when the 10-second local countdown alert elapses without rider cancellation."""

    event_id: UUID
    confirmed_at: datetime = Field(default_factory=datetime.utcnow)


class SOSCancelRequest(BaseModel):
    """Sent if the rider cancels/aborts within the 10-second local countdown window."""

    event_id: UUID
    reason: str = Field(
        default="False alarm cancelled by rider within 10-second safety window",
        max_length=300,
    )


class AudioRetentionUpdateRequest(BaseModel):
    """Allows rider to mark audio clip to be kept permanently rather than auto-deleted after 30 days."""

    keep_permanently: bool = True


class UnresponsiveCrashEscalationRequest(BaseModel):
    """Sent when mobile sensor detects major crash and rider is unresponsive after 10-second AI voice check."""

    unresponsive_duration_seconds: int = Field(default=10, description="Duration rider remained unresponsive")
    g_force_peak: float | None = Field(default=None, description="Impact spike in Gs")
    nearest_landmark: str | None = Field(default=None, description="Highway or landmark identifier")


class UnresponsiveCrashEscalationResponse(BaseModel):
    """Result of AI automated voice dispatch to Police Station and Ambulance."""

    event_id: UUID
    status: str
    is_unresponsive: bool
    police_dispatched: bool
    ambulance_dispatched: bool
    police_voice_transcript: str
    ambulance_voice_transcript: str
    map_url: str
    emergency_contacts_alerted: int
    timestamp: datetime


class SOSEventOut(BaseModel):
    """Public representation of an SOS emergency event."""

    id: UUID
    rider_id: UUID
    trigger_type: SOSTriggerTypeEnum
    status: SOSStatusEnum
    latitude: float
    longitude: float
    location_trail: list[dict[str, Any]] | None = None
    group_ride_id: UUID | None = None
    audio_clip_url: str | None = None
    audio_expires_at: datetime | None = None
    keep_audio_permanently: bool = False
    is_confirmed: bool
    confirmed_at: datetime | None = None
    cancelled_at: datetime | None = None
    is_unresponsive: bool = False
    police_dispatched: bool = False
    ambulance_dispatched: bool = False
    police_voice_transcript: str | None = None
    ambulance_voice_transcript: str | None = None
    ai_voice_call_status: dict[str, Any] | None = None
    escalation_stage: str
    dispatch_log: list[dict[str, Any]] | None = None
    created_at: datetime
    resolved_at: datetime | None = None

    model_config = {"from_attributes": True}
