"""Bike and MaintenanceReminder models — the digital garage."""

from __future__ import annotations

import enum
import uuid
from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from typing import TYPE_CHECKING

from app.models import Base

if TYPE_CHECKING:
    from app.models.rider import Rider


class ReminderTypeEnum(str, enum.Enum):
    oil_change = "oil_change"
    tire_check = "tire_check"
    chain_lube = "chain_lube"
    brake_check = "brake_check"
    general_service = "general_service"
    insurance_renewal = "insurance_renewal"
    custom = "custom"


class Bike(Base):
    """A motorcycle in a rider's digital garage."""

    __tablename__ = "bikes"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    rider_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("riders.id", ondelete="CASCADE"), nullable=False
    )
    model: Mapped[str] = mapped_column(String(200), nullable=False)
    cc: Mapped[int] = mapped_column(Integer, nullable=False)
    year: Mapped[int] = mapped_column(Integer, nullable=False)
    registration_number: Mapped[str | None] = mapped_column(String(30), nullable=True)
    insurance_expiry: Mapped[date | None] = mapped_column(Date, nullable=True)
    last_service_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    next_service_due: Mapped[date | None] = mapped_column(Date, nullable=True)
    odometer_km: Mapped[int | None] = mapped_column(Integer, nullable=True)
    photo_url: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    rider: Mapped[Rider] = relationship("Rider", back_populates="bikes")
    maintenance_reminders: Mapped[list[MaintenanceReminder]] = relationship(
        back_populates="bike", cascade="all, delete-orphan"
    )


class MaintenanceReminder(Base):
    """Scheduled maintenance tasks for a bike."""

    __tablename__ = "maintenance_reminders"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    bike_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("bikes.id", ondelete="CASCADE"), nullable=False
    )
    reminder_type: Mapped[ReminderTypeEnum] = mapped_column(
        Enum(ReminderTypeEnum, name="reminder_type_enum", create_constraint=True),
        nullable=False,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    due_date: Mapped[date] = mapped_column(Date, nullable=False)
    due_km: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False)
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    bike: Mapped["Bike"] = relationship(back_populates="maintenance_reminders")
