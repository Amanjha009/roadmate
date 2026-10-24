"""Authentication service — token creation, decoding, tier checks."""

from __future__ import annotations

from uuid import UUID

from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import UnauthorizedError
from app.core.security import create_access_token, create_refresh_token, decode_token
from app.models.rider import Rider


async def get_or_create_rider(db: AsyncSession, phone: str) -> Rider:
    """Return an existing rider or create a new one for the given phone number."""
    stmt = select(Rider).where(Rider.phone == phone)
    result = await db.execute(stmt)
    rider = result.scalar_one_or_none()

    if rider is None:
        rider = Rider(phone=phone)
        db.add(rider)
        await db.commit()
        await db.refresh(rider)

    return rider


def issue_tokens(rider_id: UUID) -> dict[str, str]:
    """Generate access + refresh token pair."""
    return {
        "access_token": create_access_token(rider_id),
        "refresh_token": create_refresh_token(rider_id),
        "token_type": "bearer",
    }


async def rider_from_token(db: AsyncSession, token: str) -> Rider:
    """Decode a JWT and return the corresponding Rider.

    Raises ``UnauthorizedError`` on any failure.
    """
    try:
        payload = decode_token(token)
        rider_id_str: str | None = payload.get("sub")
        token_type: str | None = payload.get("type")
        if rider_id_str is None or token_type != "access":
            raise UnauthorizedError("Invalid token payload")
    except JWTError as exc:
        raise UnauthorizedError(f"Token validation failed: {exc}") from exc

    rider_id = UUID(rider_id_str)
    stmt = select(Rider).where(Rider.id == rider_id)
    result = await db.execute(stmt)
    rider = result.scalar_one_or_none()
    if rider is None:
        raise UnauthorizedError("Rider not found")
    return rider


def refresh_access_token(refresh_token_str: str) -> dict[str, str]:
    """Validate a refresh token and return a new access token."""
    try:
        payload = decode_token(refresh_token_str)
        if payload.get("type") != "refresh":
            raise UnauthorizedError("Invalid token type")
        rider_id = UUID(payload["sub"])
    except (JWTError, KeyError, ValueError) as exc:
        raise UnauthorizedError(f"Refresh token invalid: {exc}") from exc

    return {
        "access_token": create_access_token(rider_id),
        "token_type": "bearer",
    }
