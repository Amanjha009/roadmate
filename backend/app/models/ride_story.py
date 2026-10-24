"""RideStory & Ride Recording Lifecycle models.

Implements:
- Recording state machine: IDLE -> ACTIVE -> PAUSED -> RESUMED -> FINISHED -> REVIEW -> STORY_READY
- Single active recording session enforcement per rider
- Telemetry persistence for route replay, 9:16 recap export, and exploration badges
"""

from __future__ import annotations

import enum
import math
import uuid
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    JSON,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models import Base


class RecordingStateEnum(str, enum.Enum):
    idle = "IDLE"
    active = "ACTIVE"
    paused = "PAUSED"
    resumed = "RESUMED"
    finished = "FINISHED"
    review = "REVIEW"
    story_ready = "STORY_READY"


class StoryVisibilityEnum(str, enum.Enum):
    public = "PUBLIC"
    followers = "FOLLOWERS"
    private = "PRIVATE"


class StoryThemeEnum(str, enum.Enum):
    mountain_escape = "Mountain Escape"
    weekend_ride = "Weekend Ride"
    long_distance_tour = "Long-Distance Tour"
    scenic_route = "Scenic Route"
    group_adventure = "Group Adventure"


class RideSession(Base):
    """Ride recording lifecycle session ensuring only one active session per rider."""

    __tablename__ = "ride_sessions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    rider_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("riders.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(128), default="Untitled Ride")
    state: Mapped[RecordingStateEnum] = mapped_column(
        Enum(RecordingStateEnum, name="recording_state_enum", create_constraint=False),
        default=RecordingStateEnum.idle,
        nullable=False,
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    paused_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    resumed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Ingested points storage (serialized list of filtered GPS fixes)
    points_data: Mapped[list[dict[str, Any]]] = mapped_column(JSON, default=list)
    raw_points_count: Mapped[int] = mapped_column(Integer, default=0)
    filtered_points_count: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    story: Mapped["RideStory | None"] = relationship(
        "RideStory", back_populates="session", uselist=False, cascade="all, delete-orphan"
    )


class RideStory(Base):
    """Published or drafted RideStory vertical recap record."""

    __tablename__ = "ride_stories"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    session_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("ride_sessions.id", ondelete="SET NULL"), nullable=True
    )
    rider_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("riders.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(140), nullable=False)
    theme: Mapped[StoryThemeEnum] = mapped_column(
        Enum(StoryThemeEnum, name="story_theme_enum", create_constraint=False),
        default=StoryThemeEnum.mountain_escape,
    )
    visibility: Mapped[StoryVisibilityEnum] = mapped_column(
        Enum(StoryVisibilityEnum, name="story_visibility_enum", create_constraint=False),
        default=StoryVisibilityEnum.public,
    )

    start_region: Mapped[str] = mapped_column(String(100), default="Unknown")
    end_region: Mapped[str] = mapped_column(String(100), default="Unknown")
    start_altitude_m: Mapped[float | None] = mapped_column(Float, nullable=True)
    end_altitude_m: Mapped[float | None] = mapped_column(Float, nullable=True)

    total_distance_km: Mapped[float] = mapped_column(Float, default=0.0)
    moving_time_seconds: Mapped[int] = mapped_column(Integer, default=0)
    elapsed_time_seconds: Mapped[int] = mapped_column(Integer, default=0)
    elevation_gain_meters: Mapped[float] = mapped_column(Float, default=0.0)
    max_speed_kmh: Mapped[float | None] = mapped_column(Float, nullable=True)
    hide_max_speed: Mapped[bool] = mapped_column(Boolean, default=True)  # Safe speed policy
    privacy_clipped: Mapped[bool] = mapped_column(Boolean, default=True)

    # Awarded exploration badges
    achievements: Mapped[list[str]] = mapped_column(JSON, default=list)

    # Processed polyline for route replay (clipped if privacy_clipped is True)
    route_polyline: Mapped[list[dict[str, Any]]] = mapped_column(JSON, default=list)

    # Social engagement counters
    likes_count: Mapped[int] = mapped_column(Integer, default=12)
    bookmarks_count: Mapped[int] = mapped_column(Integer, default=4)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    session: Mapped["RideSession | None"] = relationship("RideSession", back_populates="story")
