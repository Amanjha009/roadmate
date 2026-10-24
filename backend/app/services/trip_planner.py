"""LLM-powered trip planning service.

Calls an OpenAI-compatible chat-completion API with a structured system
prompt so the response is parseable JSON.  A mock fallback is provided
for local development/testing without an API key.
"""

from __future__ import annotations

import json
import logging
from datetime import datetime
from typing import Any

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

# ── System prompt ─────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """\
You are RoadMate AI — an expert motorcycle trip planner for Indian roads.
Given a rider's origin, destination, bike specs, experience level, departure
date and preferences, produce a single JSON object (no markdown fences) with
exactly these keys:

{
  "feasibility_score": <int 0-100>,
  "estimated_duration_days": <int>,
  "total_distance_km": <float>,
  "fuel_stops": [
    {"name": "<string>", "location": "<string>", "km_from_start": <float>, "fuel_type": "<string>"}
  ],
  "day_legs": [
    {
      "day": <int>,
      "start": "<string>",
      "end": "<string>",
      "distance_km": <float>,
      "duration_hours": <float>,
      "highlights": ["<string>"],
      "warnings": ["<string>"]
    }
  ],
  "hazard_zones": [
    {"location": "<string>", "type": "<string>", "severity": "<low|medium|high|critical>", "description": "<string>"}
  ],
  "gear_recommendations": ["<string>"],
  "best_season": "<string>",
  "emergency_numbers": [
    {"name": "<string>", "number": "<string>", "type": "<string>"}
  ]
}

Consider Indian road conditions, altitude, monsoon season, fuel availability,
and the rider's experience level.  Ensure each day leg is realistic (max ~300 km
for beginners, ~500 km for experts).  Return ONLY valid JSON.
"""


def _build_user_prompt(
    origin: str,
    destination: str,
    bike_model: str,
    bike_cc: int,
    experience_level: str,
    departure_date: datetime,
    preferences: dict[str, Any] | None,
) -> str:
    """Construct the user-facing prompt for the LLM."""
    prefs_str = json.dumps(preferences or {})
    return (
        f"Plan a motorcycle trip:\n"
        f"• Origin: {origin}\n"
        f"• Destination: {destination}\n"
        f"• Bike: {bike_model} ({bike_cc} cc)\n"
        f"• Experience: {experience_level}\n"
        f"• Departure: {departure_date.strftime('%Y-%m-%d')}\n"
        f"• Preferences: {prefs_str}\n"
    )


# ── Mock response for testing ────────────────────────────────────────────────

MOCK_ROUTE_DATA: dict[str, Any] = {
    "feasibility_score": 82,
    "estimated_duration_days": 3,
    "total_distance_km": 980.0,
    "fuel_stops": [
        {"name": "HP Petrol Pump, Ambala", "location": "Ambala, Haryana", "km_from_start": 200.0, "fuel_type": "petrol"},
        {"name": "Indian Oil, Chandigarh", "location": "Chandigarh", "km_from_start": 260.0, "fuel_type": "petrol"},
        {"name": "BPCL, Bilaspur", "location": "Bilaspur, HP", "km_from_start": 380.0, "fuel_type": "petrol"},
        {"name": "HP, Mandi", "location": "Mandi, HP", "km_from_start": 520.0, "fuel_type": "petrol"},
        {"name": "IOC, Kullu", "location": "Kullu, HP", "km_from_start": 600.0, "fuel_type": "petrol"},
    ],
    "day_legs": [
        {
            "day": 1,
            "start": "Delhi",
            "end": "Chandigarh",
            "distance_km": 260.0,
            "duration_hours": 5.5,
            "highlights": ["Murthal paranthas", "Karnal Lake"],
            "warnings": ["Heavy truck traffic on NH-44 near Panipat"],
        },
        {
            "day": 2,
            "start": "Chandigarh",
            "end": "Manali",
            "distance_km": 310.0,
            "duration_hours": 8.0,
            "highlights": ["Sundernagar Lake", "Kullu Valley views"],
            "warnings": ["Hairpin bends after Mandi", "Possible landslides near Aut Tunnel"],
        },
        {
            "day": 3,
            "start": "Manali",
            "end": "Leh (via Rohtang)",
            "distance_km": 410.0,
            "duration_hours": 12.0,
            "highlights": ["Rohtang Pass", "Keylong", "Baralacha La", "More Plains"],
            "warnings": ["Altitude sickness above 4000m", "No fuel after Tandi for 365 km"],
        },
    ],
    "hazard_zones": [
        {"location": "Rohtang Pass", "type": "landslide", "severity": "high", "description": "Frequent landslides during monsoon season"},
        {"location": "Baralacha La", "type": "flood", "severity": "medium", "description": "Water crossings can be deep in July-August"},
    ],
    "gear_recommendations": [
        "Full-face helmet",
        "Riding jacket with armour",
        "Waterproof gloves",
        "Knee guards",
        "Thermal inner layer",
        "Bungee cords / ratchet straps",
        "Puncture repair kit",
        "Jerry can (5L)",
    ],
    "best_season": "June (post-snowmelt) or September (post-monsoon)",
    "emergency_numbers": [
        {"name": "HRTC Helpline", "number": "1800-180-8008", "type": "roadside"},
        {"name": "HP Police", "number": "112", "type": "police"},
        {"name": "ITBP Rescue (Rohtang)", "number": "01902-250334", "type": "rescue"},
    ],
}


async def plan_trip(
    origin: str,
    destination: str,
    bike_model: str,
    bike_cc: int,
    experience_level: str,
    departure_date: datetime,
    preferences: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Call the LLM API to generate a trip plan.

    Falls back to a mock response when no API key is configured.
    """
    if not settings.llm_api_key:
        logger.warning("LLM_API_KEY not set — returning mock trip plan")
        return MOCK_ROUTE_DATA

    user_prompt = _build_user_prompt(
        origin, destination, bike_model, bike_cc,
        experience_level, departure_date, preferences,
    )

    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(
            f"{settings.llm_api_base_url}/chat/completions",
            headers={
                "Authorization": f"Bearer {settings.llm_api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": settings.llm_model,
                "messages": [
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": user_prompt},
                ],
                "temperature": 0.4,
                "max_tokens": 4096,
            },
        )
        response.raise_for_status()

    data = response.json()
    content: str = data["choices"][0]["message"]["content"]

    # Strip markdown fences if LLM wraps in ```json ... ```
    content = content.strip()
    if content.startswith("```"):
        content = content.split("\n", 1)[1]  # drop first line
    if content.endswith("```"):
        content = content.rsplit("```", 1)[0]
    content = content.strip()

    try:
        route_data: dict[str, Any] = json.loads(content)
    except json.JSONDecodeError:
        logger.error("LLM returned non-JSON content: %s", content[:500])
        raise

    return route_data
