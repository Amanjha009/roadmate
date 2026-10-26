"""GroupRide and GroupRideMember models."""

from __future__ import annotations

import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from typing import TYPE_CHECKING

from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models import Base
from app.models.trip import ExperienceLevelEnum

if TYPE_CHECKING:
    from app.models.rider import Rider
    from app.models.trip import Trip


class GroupRideStatusEnum(str, enum.Enum):
    planned = "planned"
    live = "live"
    completed = "completed"
    cancelled = "cancelled"


class MemberRoleEnum(str, enum.Enum):
    captain = "captain"
    sweep = "sweep"
    member = "member"


class MemberStatusEnum(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    riding = "riding"
    stopped = "stopped"
    finished = "finished"
    left = "left"


class GroupRide(Base):
    """A coordinated group ride with membership management."""

    __tablename__ = "group_rides"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    captain_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("riders.id", ondelete="CASCADE"), nullable=False
    )
    title: Mapped[str] = mapped_column(String(300), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    join_code: Mapped[str | None] = mapped_column(String(20), index=True, nullable=True)
    trip_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id", ondelete="SET NULL"), nullable=True
    )
    route_summary: Mapped[str] = mapped_column(Text, nullable=False)
    required_gear: Mapped[list | None] = mapped_column(JSON, nullable=True)
    max_riders: Mapped[int] = mapped_column(Integer, nullable=False)
    min_experience: Mapped[ExperienceLevelEnum] = mapped_column(
        Enum(ExperienceLevelEnum, name="experience_level_enum", create_constraint=True,
             create_type=False),
        default=ExperienceLevelEnum.beginner,
    )
    min_verification_level: Mapped[int] = mapped_column(Integer, default=1)
    is_women_only: Mapped[bool] = mapped_column(Boolean, default=False)
    status: Mapped[GroupRideStatusEnum] = mapped_column(
        Enum(GroupRideStatusEnum, name="group_ride_status_enum", create_constraint=True),
        default=GroupRideStatusEnum.planned,
    )
    start_time: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    captain: Mapped[Rider] = relationship("Rider", lazy="selectin")
    trip: Mapped[Trip | None] = relationship("Trip", lazy="selectin")
    members: Mapped[list[GroupRideMember]] = relationship(
        back_populates="group_ride", cascade="all, delete-orphan"
    )


class GroupRideMember(Base):
    """A rider's membership in a group ride."""

    __tablename__ = "group_ride_members"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    group_ride_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("group_rides.id", ondelete="CASCADE"),
        nullable=False,
    )
    rider_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("riders.id", ondelete="CASCADE"), nullable=False
    )
    role: Mapped[MemberRoleEnum] = mapped_column(
        Enum(MemberRoleEnum, name="member_role_enum", create_constraint=True),
        default=MemberRoleEnum.member,
    )
    status: Mapped[MemberStatusEnum] = mapped_column(
        Enum(MemberStatusEnum, name="member_status_enum", create_constraint=True),
        default=MemberStatusEnum.pending,
    )
    last_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    last_lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    last_location_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    joined_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    group_ride: Mapped[GroupRide] = relationship(back_populates="members")
    rider: Mapped[Rider] = relationship("Rider", lazy="selectin")
