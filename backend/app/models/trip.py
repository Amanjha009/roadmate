"""Trip model — AI-planned motorcycle trips."""

from __future__ import annotations

import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models import Base


class ExperienceLevelEnum(str, enum.Enum):
    beginner = "beginner"
    intermediate = "intermediate"
    advanced = "advanced"
    expert = "expert"


class TripStatusEnum(str, enum.Enum):
    draft = "draft"
    planned = "planned"
    active = "active"
    completed = "completed"
    cancelled = "cancelled"


class Trip(Base):
    """A planned motorcycle trip with AI-generated route data."""

    __tablename__ = "trips"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    rider_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("riders.id", ondelete="CASCADE"), nullable=False
    )
    title: Mapped[str] = mapped_column(String(300), nullable=False)
    origin: Mapped[str] = mapped_column(String(300), nullable=False)
    destination: Mapped[str] = mapped_column(String(300), nullable=False)
    bike_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("bikes.id", ondelete="SET NULL"), nullable=True
    )
    departure_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    experience_level: Mapped[ExperienceLevelEnum] = mapped_column(
        Enum(ExperienceLevelEnum, name="experience_level_enum", create_constraint=True),
        nullable=False,
    )
    preferences: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    route_data: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    status: Mapped[TripStatusEnum] = mapped_column(
        Enum(TripStatusEnum, name="trip_status_enum", create_constraint=True),
        default=TripStatusEnum.draft,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    rider: Mapped["Rider"] = relationship("Rider", back_populates="trips")  # noqa: F821
    bike: Mapped["Bike | None"] = relationship("Bike", lazy="selectin")  # noqa: F821
