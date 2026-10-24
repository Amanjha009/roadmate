"""RoadMate India — Dual-Mode Zero-Config Database Engine.

Seamlessly runs out-of-the-box on SQLite (roadmate_local.db) when Docker is off,
and upgrades to PostgreSQL 16 + PostGIS 3.4 when Docker is running.
"""

from __future__ import annotations

import logging
import os
import socket
from typing import AsyncGenerator
from urllib.parse import urlparse

from geoalchemy2 import Geography
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.ext.compiler import compiles
import geoalchemy2.admin.dialects.sqlite as s_admin

from app.config import settings

logger = logging.getLogger("roadmate.database")

# ── SQLite GeoAlchemy2 Compatibility Patch ───────────────────────────────────
# When using SQLite without SpatiaLite C extension, compile Geography as TEXT
# and bypass SpatiaLite's CreateSpatialIndex DDL hook.
@compiles(Geography, "sqlite")
def _compile_geography_sqlite(type_, compiler, **kw):
    return "TEXT"

s_admin.after_create = lambda *args, **kwargs: None


def is_postgres_available(db_url: str) -> bool:
    """Test whether the PostgreSQL server specified by db_url is currently reachable."""
    try:
        parsed = urlparse(db_url)
        host = parsed.hostname or "localhost"
        port = parsed.port or 5432
        with socket.create_connection((host, port), timeout=0.6):
            return True
    except (OSError, ValueError):
        return False


def get_active_database_url() -> str:
    """Determine the database URL: use PostgreSQL if reachable, else fallback to SQLite."""
    configured_url = settings.database_url
    if "postgresql" in configured_url:
        if is_postgres_available(configured_url):
            logger.info("⚡ [Dual-Mode DB] Connected to PostgreSQL + PostGIS (%s)", configured_url)
            return configured_url
        else:
            logger.warning(
                "⚠️ [Dual-Mode DB] PostgreSQL unreachable at localhost:5432. "
                "Activating zero-config SQLite mode (roadmate_local.db)."
            )
            return "sqlite+aiosqlite:///roadmate_local.db"
    return configured_url


ACTIVE_DB_URL = get_active_database_url()
IS_SQLITE = ACTIVE_DB_URL.startswith("sqlite")

if IS_SQLITE:
    engine = create_async_engine(
        ACTIVE_DB_URL,
        echo=False,
        connect_args={"check_same_thread": False},
    )
else:
    engine = create_async_engine(
        ACTIVE_DB_URL,
        echo=False,
        pool_size=20,
        max_overflow=10,
        pool_pre_ping=True,
    )

async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


def init_sqlite_tables_sync() -> None:
    """Ensure all tables exist in SQLite without requiring manual migrations."""
    if IS_SQLITE:
        from sqlalchemy import create_engine
        from app.models import Base
        sync_engine = create_engine("sqlite:///roadmate_local.db")
        Base.metadata.create_all(sync_engine)


init_sqlite_tables_sync()

