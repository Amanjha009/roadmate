"""SQLAlchemy declarative base and model imports.

Import all model modules here so that ``Base.metadata`` sees every table
when Alembic (or ``create_all``) inspects it.
"""

from __future__ import annotations

from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Base class for all ORM models."""

    pass


# Import every model module so tables are registered on Base.metadata.
from app.models.rider import Rider, OTPCode, VerificationDocument, EmergencyContact  # noqa: E402, F401
from app.models.bike import Bike, MaintenanceReminder  # noqa: E402, F401
from app.models.trip import Trip  # noqa: E402, F401
from app.models.hazard import HazardReport, HazardVerification  # noqa: E402, F401
from app.models.group_ride import GroupRide, GroupRideMember  # noqa: E402, F401
from app.models.sos import SOSEvent  # noqa: E402, F401
from app.models.safety import UnsafeAreaReport  # noqa: E402, F401
from app.models.ride_history import RideHistory  # noqa: E402, F401
from app.models.ride_story import RideSession, RideStory  # noqa: E402, F401
from app.models.touring_service import TouringService  # noqa: E402, F401
