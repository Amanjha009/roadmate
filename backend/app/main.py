"""RoadMate India — FastAPI application entrypoint."""

from __future__ import annotations

from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import api_v1_router
from app.api.v1.hazards import router as hazards_router
from app.api.v1.live_rides import router as live_rides_router
from app.config import settings
from app.services.redis_pubsub import ride_pubsub


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Startup and shutdown lifecycle handler."""
    # Ensure database schema is initialized in zero-config SQLite mode
    from app.database import engine, IS_SQLITE
    from app.models import Base

    if IS_SQLITE:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

    yield
    # Teardown connections cleanly
    await ride_pubsub.close()


app = FastAPI(
    title="RoadMate India API",
    description="Safety-first motorcycle touring platform for Indian riders with voice-activated SOS and PostGIS radar.",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount versioned API routes (/api/v1/...)
app.include_router(api_v1_router)

# Also mount live WebSocket and hazard polling at root (/ws/rides/:id, /hazards/nearby)
app.include_router(live_rides_router)
app.include_router(hazards_router)


@app.get("/health", tags=["Health"])
async def health_check() -> dict[str, str]:
    """Health probe endpoint for containers / Kubernetes."""
    return {"status": "healthy", "service": "roadmate-backend"}
