"""Pydantic v2 schemas for Touring Support Network and Fuel Range Planner."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.touring_service import ServiceCategoryEnum, ServiceProvenanceEnum


class FuelRangeRequest(BaseModel):
    """Input payload for motorcycle fuel range and dry-zone deficit calculation."""

    tank_capacity_l: float = Field(..., gt=0.0, le=40.0, description="Fuel tank capacity in litres")
    recent_efficiency_km_l: float = Field(..., gt=0.0, le=75.0, description="Recent average efficiency (km/L)")
    current_fuel_l: float = Field(..., ge=0.0, le=40.0, description="Current estimated fuel in tank (L)")
    safety_reserve_l: float = Field(2.0, ge=0.0, le=10.0, description="Safety reserve fuel to preserve (L)")
    next_pump_distance_km: float = Field(..., ge=0.0, description="Distance to next verified pump along route")
    is_high_altitude: bool = Field(False, description="Whether route crosses >3,000m high-altitude terrain")


class FuelRangeResponse(BaseModel):
    """Calculated fuel range, reserve margin, and deficit recommendations."""

    total_estimated_range_km: float
    safe_usable_range_km: float
    usable_fuel_litres: float
    next_pump_distance_km: float
    net_margin_km: float
    status: Literal["SAFE", "DEFICIT_WARNING"]
    deficit_litres_needed: float | None
    recommended_jerry_can_litres: int | None
    advisory: str
    disclaimer: str


class TouringServiceQuery(BaseModel):
    """Filter options for touring services along highway corridors."""

    category: ServiceCategoryEnum | None = None
    provenance: ServiceProvenanceEnum | None = None
    corridor: str | None = None
    women_safe_only: bool = False
    has_o2_only: bool = False
    spoke_tube_only: bool = False


class TouringServiceOut(BaseModel):
    id: UUID
    name: str
    category: str
    provenance: str
    highway_corridor: str
    latitude: float
    longitude: float
    opening_hours: str
    phone: str | None
    has_high_altitude_o2: bool
    is_spoke_tube_specialist: bool
    is_women_safe_stay: bool
    guarded_parking: bool
    clean_washrooms: bool
    cctv_equipped: bool
    is_cash_only: bool
    private_notes: str | None
    last_confirmed_at: datetime
    confirmations_count: int
    is_reported_closed: bool

    model_config = {"from_attributes": True}


class RouteCopilotRequest(BaseModel):
    start_name: str = Field("Manali", description="Origin name")
    start_lat: float = Field(32.2396, ge=-90.0, le=90.0)
    start_lng: float = Field(77.1887, ge=-180.0, le=180.0)
    end_name: str = Field("Keylong", description="Destination name")
    end_lat: float = Field(32.5710, ge=-90.0, le=90.0)
    end_lng: float = Field(77.0320, ge=-180.0, le=180.0)
    bike_model: str = Field("Royal Enfield Himalayan 450", max_length=100)
    bike_cc: int = Field(452, ge=50, le=2500)


class RouteCopilotResponse(BaseModel):
    source: str
    start_name: str
    end_name: str
    distance_km: float
    duration_hours: float
    duration_minutes: float
    coordinates: list[list[float]]
    weather_summary: dict[str, Any]
    expressway_restrictions: list[dict[str, Any]]
    key_waypoint_elevations: list[dict[str, Any]]
    recommended_fuel_stops: list[dict[str, Any]]

