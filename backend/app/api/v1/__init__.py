"""API v1 router registry."""

from fastapi import APIRouter
from app.api.v1.convoy_sync import router as convoy_router
from app.api.v1.group_rides import router as group_rides_router
from app.api.v1.hazards import router as hazards_router
from app.api.v1.live_rides import router as live_rides_router
from app.api.v1.ridestory import router as ridestory_router
from app.api.v1.sos import router as sos_router
from app.api.v1.touring_support import router as touring_router

api_v1_router = APIRouter(prefix="/api/v1")
api_v1_router.include_router(sos_router)
api_v1_router.include_router(hazards_router)
api_v1_router.include_router(live_rides_router)
api_v1_router.include_router(ridestory_router)
api_v1_router.include_router(touring_router)
api_v1_router.include_router(convoy_router)
api_v1_router.include_router(group_rides_router)

