"""HazardReport model — crowd-sourced road hazard reports with PostGIS."""

from __future__ import annotations

import enum
import uuid
from datetime import datetime

from geoalchemy2 import Geography
from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from typing import TYPE_CHECKING

from app.models import Base

if TYPE_CHECKING:
    from app.models.rider import Rider


class HazardTypeEnum(str, enum.Enum):
    black_ice = "black_ice"
    water_crossing = "water_crossing"
    loose_gravel = "loose_gravel"
    landslide = "landslide"
    road_closure = "road_closure"
    construction = "construction"
    pothole = "pothole"
    dangerous_bend = "dangerous_bend"
    # Legacy / alias support
    flood = "flood"
    accident = "accident"
    roadblock = "roadblock"
    animal_crossing = "animal_crossing"
    poor_visibility = "poor_visibility"
    other = "other"


# Category-specific TTLs in hours
HAZARD_TTL_HOURS: dict[str, int] = {
    HazardTypeEnum.black_ice.value: 8,
    HazardTypeEnum.water_crossing.value: 12,
    HazardTypeEnum.loose_gravel.value: 48,
    HazardTypeEnum.landslide.value: 72,
    HazardTypeEnum.road_closure.value: 168,
    HazardTypeEnum.construction.value: 336,
    HazardTypeEnum.pothole.value: 720,
    HazardTypeEnum.dangerous_bend.value: 2160,
    HazardTypeEnum.flood.value: 12,
    HazardTypeEnum.accident.value: 6,
    HazardTypeEnum.roadblock.value: 72,
    HazardTypeEnum.animal_crossing.value: 24,
    HazardTypeEnum.poor_visibility.value: 8,
    HazardTypeEnum.other.value: 24,
}


class HazardLifecycleEnum(str, enum.Enum):
    reported = "reported"
    under_review = "under_review"
    confirmed = "confirmed"
    disputed = "disputed"
    resolved = "resolved"
    expired = "expired"


class SeverityEnum(str, enum.Enum):
    low = "low"
    medium = "medium"
    high = "high"
    critical = "critical"


class HazardReport(Base):
    """A crowd-sourced road hazard report with a PostGIS geography point."""

    __tablename__ = "hazard_reports"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    reporter_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("riders.id", ondelete="SET NULL"), nullable=True
    )
    idempotency_key: Mapped[str | None] = mapped_column(
        String(128), unique=True, index=True, nullable=True
    )
    location = mapped_column(
        Geography(geometry_type="POINT", srid=4326), nullable=False
    )
    hazard_type: Mapped[HazardTypeEnum] = mapped_column(
        Enum(HazardTypeEnum, name="hazard_type_enum", create_constraint=False),
        nullable=False,
    )
    lifecycle_status: Mapped[HazardLifecycleEnum] = mapped_column(
        Enum(HazardLifecycleEnum, name="hazard_lifecycle_enum", create_constraint=False),
        default=HazardLifecycleEnum.reported,
    )
    source_type: Mapped[str] = mapped_column(
        String(32), default="COMMUNITY"  # BRO_POLICE, VERIFIED_RIDER, COMMUNITY
    )
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    photo_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    confidence_score: Mapped[float] = mapped_column(Float, default=0.5)
    severity: Mapped[SeverityEnum] = mapped_column(
        Enum(SeverityEnum, name="severity_enum", create_constraint=False),
        default=SeverityEnum.medium,
    )
    expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    last_confirmed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    upvotes: Mapped[int] = mapped_column(Integer, default=0)
    downvotes: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    reporter: Mapped[Rider | None] = relationship("Rider", lazy="selectin")
    verifications: Mapped[list[HazardVerification]] = relationship(
        "HazardVerification", back_populates="hazard", cascade="all, delete-orphan", lazy="selectin"
    )


class HazardVerification(Base):
    """Voter verification record enforcing proximity guard and 1-vote-per-rider."""

    __tablename__ = "hazard_verifications"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    hazard_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("hazard_reports.id", ondelete="CASCADE"), nullable=False, index=True
    )
    voter_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=False, index=True
    )
    action: Mapped[str] = mapped_column(
        String(20), nullable=False  # "CONFIRM", "DISPUTE", "RESOLVE"
    )
    voter_lat: Mapped[float] = mapped_column(Float, nullable=False)
    voter_lng: Mapped[float] = mapped_column(Float, nullable=False)
    distance_meters: Mapped[float] = mapped_column(Float, default=0.0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    hazard: Mapped["HazardReport"] = relationship("HazardReport", back_populates="verifications")

    __table_args__ = (
        UniqueConstraint("hazard_id", "voter_id", name="uq_hazard_voter"),
    )

