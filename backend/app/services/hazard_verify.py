"""LLM-based hazard report verification.

Assigns a confidence score and auto-expiry to a newly submitted hazard.
For now this is a rule-based placeholder that can be swapped for a real
LLM call when the product matures.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from app.models.hazard import HazardTypeEnum, SeverityEnum

# Default expiry hours by hazard type
_EXPIRY_HOURS: dict[HazardTypeEnum, int] = {
    HazardTypeEnum.pothole: 168,        # 7 days
    HazardTypeEnum.landslide: 72,       # 3 days
    HazardTypeEnum.flood: 48,           # 2 days
    HazardTypeEnum.accident: 12,
    HazardTypeEnum.roadblock: 24,
    HazardTypeEnum.animal_crossing: 6,
    HazardTypeEnum.poor_visibility: 8,
    HazardTypeEnum.construction: 336,   # 14 days
    HazardTypeEnum.other: 24,
}

_SEVERITY_CONFIDENCE: dict[SeverityEnum, float] = {
    SeverityEnum.low: 0.5,
    SeverityEnum.medium: 0.65,
    SeverityEnum.high: 0.8,
    SeverityEnum.critical: 0.9,
}


def verify_hazard(
    hazard_type: HazardTypeEnum,
    severity: SeverityEnum,
    description: str | None = None,
    has_photo: bool = False,
) -> dict[str, Any]:
    """Return a confidence score (0-1) and an expiry datetime for a hazard report.

    A real implementation would call the LLM with the description + photo
    to assess plausibility.  This rule-based version is suitable for MVP.
    """
    base_confidence = _SEVERITY_CONFIDENCE.get(severity, 0.5)

    # Boost confidence when photo or description supplied
    if has_photo:
        base_confidence = min(base_confidence + 0.1, 1.0)
    if description and len(description) > 20:
        base_confidence = min(base_confidence + 0.05, 1.0)

    expiry_hours = _EXPIRY_HOURS.get(hazard_type, 24)
    expires_at = datetime.now(timezone.utc) + timedelta(hours=expiry_hours)

    return {
        "confidence_score": round(base_confidence, 2),
        "expires_at": expires_at,
    }
