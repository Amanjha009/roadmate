"""Auth-related Pydantic v2 schemas."""

from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel, Field


# ── OTP ───────────────────────────────────────────────────────────────────────


class OTPRequest(BaseModel):
    """Request body for ``POST /send-otp``."""

    phone: str = Field(..., min_length=10, max_length=15, examples=["+919876543210"])


class OTPVerify(BaseModel):
    """Request body for ``POST /verify-otp``."""

    phone: str = Field(..., min_length=10, max_length=15, examples=["+919876543210"])
    code: str = Field(..., min_length=4, max_length=8, examples=["482913"])


# ── Tokens ────────────────────────────────────────────────────────────────────


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"


class RefreshTokenRequest(BaseModel):
    refresh_token: str


# ── Verification upload ──────────────────────────────────────────────────────


class VerificationUploadResponse(BaseModel):
    id: UUID
    document_type: str
    document_url: str
    status: str
