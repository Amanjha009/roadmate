"""Touring Support Network models.

Supports motorcycle touring services along highway corridors:
- FUEL_STATION, PUNCTURE_REPAIR, MECHANIC, TOWING_RSA, HOSPITAL, WOMEN_SAFE_STAY, REST_STOP
- Provenance badges: VERIFIED_PARTNER, MAP_PROVIDER, COMMUNITY_SUBMITTED, WOMEN_RIDER_AUDITED
- Cash-only / offline warnings, high-altitude O2 availability, puncture specialist tags
"""

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
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models import Base


class ServiceCategoryEnum(str, enum.Enum):
    fuel_station = "FUEL_STATION"
    puncture_repair = "PUNCTURE_REPAIR"
    mechanic = "MECHANIC"
    towing_rsa = "TOWING_RSA"
    hospital = "HOSPITAL"
    women_safe_stay = "WOMEN_SAFE_STAY"
    rest_stop = "REST_STOP"


class ServiceProvenanceEnum(str, enum.Enum):
    verified_partner = "VERIFIED_PARTNER"
    map_provider = "MAP_PROVIDER"
    community_submitted = "COMMUNITY_SUBMITTED"
    women_rider_audited = "WOMEN_RIDER_AUDITED"


class TouringService(Base):
    """Touring assistance or amenity point along highway corridors."""

    __tablename__ = "touring_services"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(140), nullable=False)
    category: Mapped[ServiceCategoryEnum] = mapped_column(
        Enum(ServiceCategoryEnum, name="service_category_enum", create_constraint=False),
        nullable=False,
        index=True,
    )
    provenance: Mapped[ServiceProvenanceEnum] = mapped_column(
        Enum(ServiceProvenanceEnum, name="service_provenance_enum", create_constraint=False),
        default=ServiceProvenanceEnum.community_submitted,
    )
    highway_corridor: Mapped[str] = mapped_column(String(100), default="National Highway")
    location = mapped_column(
        Geography(geometry_type="POINT", srid=4326), nullable=False
    )
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)

    opening_hours: Mapped[str] = mapped_column(String(60), default="06:00 - 21:00")
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)

    # Feature indicators for touring riders
    has_high_altitude_o2: Mapped[bool] = mapped_column(Boolean, default=False)
    is_spoke_tube_specialist: Mapped[bool] = mapped_column(Boolean, default=False)
    is_women_safe_stay: Mapped[bool] = mapped_column(Boolean, default=False)
    guarded_parking: Mapped[bool] = mapped_column(Boolean, default=False)
    clean_washrooms: Mapped[bool] = mapped_column(Boolean, default=False)
    cctv_equipped: Mapped[bool] = mapped_column(Boolean, default=False)
    is_cash_only: Mapped[bool] = mapped_column(Boolean, default=False)

    private_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    last_confirmed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    confirmations_count: Mapped[int] = mapped_column(Integer, default=1)
    is_reported_closed: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
