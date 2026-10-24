"""RideHistory model — completed ride records for trust-score computation."""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models import Base


class RideHistory(Base):
    """Record of a completed ride used for trust score calculations."""

    __tablename__ = "ride_history"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    rider_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("riders.id", ondelete="CASCADE"), nullable=False
    )
    trip_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id", ondelete="SET NULL"), nullable=True
    )
    group_ride_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("group_rides.id", ondelete="SET NULL"),
        nullable=True,
    )
    distance_km: Mapped[float] = mapped_column(Float, nullable=False)
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    rating_given: Mapped[float | None] = mapped_column(Float, nullable=True)
    rating_received: Mapped[float | None] = mapped_column(Float, nullable=True)
    hazards_reported: Mapped[int] = mapped_column(Integer, default=0)
    hazards_accepted: Mapped[int] = mapped_column(Integer, default=0)
    misconduct_reported: Mapped[bool] = mapped_column(Boolean, default=False)
    completed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
