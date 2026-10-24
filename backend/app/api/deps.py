"""FastAPI dependencies — database sessions, authenticated rider injection."""

from __future__ import annotations

from typing import AsyncGenerator

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import UnauthorizedError
from app.database import async_session_factory
from app.models.rider import Rider
from app.services.auth import rider_from_token


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Yield an async database session per request."""
    async with async_session_factory() as session:
        try:
            yield session
        finally:
            await session.close()


async def get_current_rider(
    authorization: str | None = Header(None),
    db: AsyncSession = Depends(get_db),
) -> Rider:
    """Extract Bearer JWT and return the authenticated Rider."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or malformed Authorization header. Expected 'Bearer <token>'.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = authorization.split(" ", 1)[1]
    try:
        rider = await rider_from_token(db, token)
        return rider
    except UnauthorizedError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
            headers={"WWW-Authenticate": "Bearer"},
        )
