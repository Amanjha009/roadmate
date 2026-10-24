"""Rider-related models: Rider, OTPCode, VerificationDocument, EmergencyContact."""

from __future__ import annotations

import enum
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Float, Integer, String, Text, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship as sa_relationship

from app.models import Base


# ── Enums ─────────────────────────────────────────────────────────────────────


class GenderEnum(str, enum.Enum):
    male = "male"
    female = "female"
    other = "other"
    undisclosed = "undisclosed"


class DocumentTypeEnum(str, enum.Enum):
    government_id = "government_id"
    selfie_liveness = "selfie_liveness"
    bike_ownership = "bike_ownership"


class DocumentStatusEnum(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"


# ── Models ────────────────────────────────────────────────────────────────────


class Rider(Base):
    """Core user entity.  Every authenticated person is a 'rider'."""

    __tablename__ = "riders"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    phone: Mapped[str] = mapped_column(String(20), unique=True, index=True, nullable=False)
    name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    gender: Mapped[GenderEnum | None] = mapped_column(
        Enum(GenderEnum, name="gender_enum", create_constraint=True),
        nullable=True,
        default=GenderEnum.undisclosed,
    )
    verification_level: Mapped[int] = mapped_column(Integer, default=1)
    trust_score: Mapped[float] = mapped_column(Float, default=50.0)
    is_women_circle_eligible: Mapped[bool] = mapped_column(Boolean, default=False)
    blood_group: Mapped[str | None] = mapped_column(String(10), default="O+", nullable=True)
    medical_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    verification_documents: Mapped[list["VerificationDocument"]] = sa_relationship(
        back_populates="rider", cascade="all, delete-orphan"
    )
    emergency_contacts: Mapped[list["EmergencyContact"]] = sa_relationship(
        back_populates="rider", cascade="all, delete-orphan"
    )
    bikes: Mapped[list["Bike"]] = sa_relationship(  # noqa: F821
        "Bike", back_populates="rider", cascade="all, delete-orphan"
    )
    trips: Mapped[list["Trip"]] = sa_relationship(  # noqa: F821
        "Trip", back_populates="rider", cascade="all, delete-orphan"
    )


class OTPCode(Base):
    """Short-lived OTP codes for phone-based authentication."""

    __tablename__ = "otp_codes"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    phone: Mapped[str] = mapped_column(String(20), index=True, nullable=False)
    code: Mapped[str] = mapped_column(String(10), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    is_used: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class VerificationDocument(Base):
    """Documents uploaded by riders for identity / bike verification."""

    __tablename__ = "verification_documents"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    rider_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("riders.id", ondelete="CASCADE"), nullable=False
    )
    document_type: Mapped[DocumentTypeEnum] = mapped_column(
        Enum(DocumentTypeEnum, name="document_type_enum", create_constraint=True),
        nullable=False,
    )
    document_url: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[DocumentStatusEnum] = mapped_column(
        Enum(DocumentStatusEnum, name="document_status_enum", create_constraint=True),
        default=DocumentStatusEnum.pending,
    )
    reviewer_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    rider: Mapped["Rider"] = sa_relationship(back_populates="verification_documents")


class EmergencyContact(Base):
    """Emergency contacts attached to a rider profile."""

    __tablename__ = "emergency_contacts"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    rider_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("riders.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    phone: Mapped[str] = mapped_column(String(20), nullable=False)
    relationship: Mapped[str] = mapped_column(String(60), nullable=False)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False)
    priority: Mapped[int] = mapped_column(Integer, default=1)
    telegram_chat_id: Mapped[str | None] = mapped_column(String(50), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    rider: Mapped["Rider"] = sa_relationship(back_populates="emergency_contacts")
