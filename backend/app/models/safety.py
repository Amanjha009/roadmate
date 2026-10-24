"""UnsafeAreaReport model — anonymous safety reports with PostGIS."""

from __future__ import annotations

import enum
import uuid
from datetime import datetime

from geoalchemy2 import Geography
from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models import Base


class UnsafeAreaCategoryEnum(str, enum.Enum):
    harassment = "harassment"
    poor_lighting = "poor_lighting"
    isolated_area = "isolated_area"
    known_danger = "known_danger"
    other = "other"


class UnsafeAreaReport(Base):
    """Anonymous reports of unsafe areas for riders (especially women)."""

    __tablename__ = "unsafe_area_reports"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    reporter_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("riders.id", ondelete="SET NULL"), nullable=True
    )
    location = mapped_column(
        Geography(geometry_type="POINT", srid=4326), nullable=False
    )
    description: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[UnsafeAreaCategoryEnum] = mapped_column(
        Enum(
            UnsafeAreaCategoryEnum,
            name="unsafe_area_category_enum",
            create_constraint=True,
        ),
        nullable=False,
    )
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
