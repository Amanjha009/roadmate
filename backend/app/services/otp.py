"""OTP generation, storage and verification service."""

from __future__ import annotations

import random
import string
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.rider import OTPCode


async def generate_otp(db: AsyncSession, phone: str) -> str:
    """Generate a random 6-digit OTP, persist it, and return the code.

    In production you would also dispatch the OTP via SMS here.
    """
    code = "".join(random.choices(string.digits, k=settings.otp_length))
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.otp_expiry_minutes)

    otp = OTPCode(phone=phone, code=code, expires_at=expires_at)
    db.add(otp)
    await db.commit()

    # TODO: integrate SMS gateway (e.g. Twilio / MSG91) for production
    print(f"[DEV OTP] {phone} → {code}")  # noqa: T201
    return code


async def verify_otp(db: AsyncSession, phone: str, code: str) -> bool:
    """Verify a submitted OTP code.

    Returns ``True`` if valid and marks the code as used.
    """
    now = datetime.now(timezone.utc)
    stmt = (
        select(OTPCode)
        .where(
            OTPCode.phone == phone,
            OTPCode.code == code,
            OTPCode.is_used.is_(False),
            OTPCode.expires_at > now,
        )
        .order_by(OTPCode.created_at.desc())
        .limit(1)
    )
    result = await db.execute(stmt)
    otp = result.scalar_one_or_none()

    if otp is None:
        return False

    otp.is_used = True
    await db.commit()
    return True
