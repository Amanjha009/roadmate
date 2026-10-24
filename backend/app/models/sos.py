"""SOSEvent model — emergency panic-button, voice trigger, and crash detection events."""

from __future__ import annotations

import enum
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import Boolean, DateTime, Enum, Float, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models import Base


class SOSTriggerTypeEnum(str, enum.Enum):
    manual = "manual"
    crash_detected = "crash_detected"
    voice = "voice"


class SOSStatusEnum(str, enum.Enum):
    active = "active"
    resolved = "resolved"
    false_alarm = "false_alarm"
    cancelled = "cancelled"


class SOSEvent(Base):
    """An emergency SOS event triggered by a rider via voice, crash detection, or manual button."""

    __tablename__ = "sos_events"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    rider_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("riders.id", ondelete="CASCADE"), nullable=False
    )
    trigger_type: Mapped[SOSTriggerTypeEnum] = mapped_column(
        Enum(SOSTriggerTypeEnum, name="sos_trigger_type_enum", create_constraint=True),
        nullable=False,
    )
    status: Mapped[SOSStatusEnum] = mapped_column(
        Enum(SOSStatusEnum, name="sos_status_enum", create_constraint=True),
        default=SOSStatusEnum.active,
    )
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    location_trail: Mapped[list | None] = mapped_column(JSON, nullable=True)
    group_ride_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("group_rides.id", ondelete="SET NULL"),
        nullable=True,
    )

    # ── Audio Context & Consent (30-day retention policy) ────────────────────
    audio_clip_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    audio_expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    keep_audio_permanently: Mapped[bool] = mapped_column(Boolean, default=False)

    # ── Confirmation & 10-second Cancel Window Tracking ──────────────────────
    # The 10-second cancel window does NOT block GPS/contact queueing;
    # it only gates the final escalated external dispatch.
    is_confirmed: Mapped[bool] = mapped_column(Boolean, default=False)
    confirmed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    cancelled_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # ── Multi-Channel Escalation Stage ───────────────────────────────────────
    # Stages: "pending_confirmation", "push_dispatched", "sms_fallback_dispatched",
    #         "telegram_dispatched", "cancelled", "completed", "unresponsive_escalated"
    escalation_stage: Mapped[str] = mapped_column(
        String(50), default="pending_confirmation"
    )
    is_unresponsive: Mapped[bool] = mapped_column(Boolean, default=False)
    police_dispatched: Mapped[bool] = mapped_column(Boolean, default=False)
    ambulance_dispatched: Mapped[bool] = mapped_column(Boolean, default=False)
    police_voice_transcript: Mapped[str | None] = mapped_column(Text, nullable=True)
    ambulance_voice_transcript: Mapped[str | None] = mapped_column(Text, nullable=True)
    ai_voice_call_status: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    dispatch_log: Mapped[list | None] = mapped_column(JSON, nullable=True)

    resolved_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    rider: Mapped["Rider"] = relationship("Rider", lazy="selectin")  # noqa: F821
    group_ride: Mapped["GroupRide | None"] = relationship("GroupRide", lazy="selectin")  # noqa: F821
