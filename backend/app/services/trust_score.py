"""Trust-score computation service.

trust_score = (
    base_score(50)
  + completed_rides_bonus   (up to +20, 1 pt per ride, max 20)
  + avg_rating_bonus         (up to +15, (avg_rating − 3) × 7.5)
  + hazard_acceptance_bonus  (up to +10, acceptance_rate × 10)
  + misconduct_penalty       (−25 per misconduct flag)
).clamp(0, 100)
"""

from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.ride_history import RideHistory
from app.models.rider import Rider

BASE_SCORE = 50.0
MAX_RIDES_BONUS = 20.0
MAX_RATING_BONUS = 15.0
MAX_HAZARD_BONUS = 10.0
MISCONDUCT_PENALTY = 25.0


async def compute_trust_score(db: AsyncSession, rider_id: "str | __import__('uuid').UUID") -> float:
    """Compute and persist the trust score for a rider.

    Returns the new score.
    """
    # ── Completed rides count ─────────────────────────────────────────────
    rides_count_q = (
        select(func.count())
        .select_from(RideHistory)
        .where(RideHistory.rider_id == rider_id)
    )
    rides_count: int = (await db.execute(rides_count_q)).scalar() or 0
    completed_rides_bonus = min(float(rides_count), MAX_RIDES_BONUS)

    # ── Average rating received ───────────────────────────────────────────
    avg_rating_q = (
        select(func.avg(RideHistory.rating_received))
        .where(
            RideHistory.rider_id == rider_id,
            RideHistory.rating_received.isnot(None),
        )
    )
    avg_rating: float | None = (await db.execute(avg_rating_q)).scalar()
    if avg_rating is not None and avg_rating > 3.0:
        avg_rating_bonus = min((avg_rating - 3.0) * 7.5, MAX_RATING_BONUS)
    else:
        avg_rating_bonus = 0.0

    # ── Hazard acceptance rate ────────────────────────────────────────────
    hazard_q = select(
        func.coalesce(func.sum(RideHistory.hazards_reported), 0),
        func.coalesce(func.sum(RideHistory.hazards_accepted), 0),
    ).where(RideHistory.rider_id == rider_id)
    hazard_row = (await db.execute(hazard_q)).one()
    total_reported: int = hazard_row[0]
    total_accepted: int = hazard_row[1]
    if total_reported > 0:
        acceptance_rate = total_accepted / total_reported
        hazard_acceptance_bonus = min(acceptance_rate * MAX_HAZARD_BONUS, MAX_HAZARD_BONUS)
    else:
        hazard_acceptance_bonus = 0.0

    # ── Misconduct penalty ────────────────────────────────────────────────
    misconduct_count_q = (
        select(func.count())
        .select_from(RideHistory)
        .where(
            RideHistory.rider_id == rider_id,
            RideHistory.misconduct_reported.is_(True),
        )
    )
    misconduct_count: int = (await db.execute(misconduct_count_q)).scalar() or 0
    misconduct_total_penalty = misconduct_count * MISCONDUCT_PENALTY

    # ── Final score ───────────────────────────────────────────────────────
    score = (
        BASE_SCORE
        + completed_rides_bonus
        + avg_rating_bonus
        + hazard_acceptance_bonus
        - misconduct_total_penalty
    )
    score = max(0.0, min(score, 100.0))

    # Persist
    stmt = select(Rider).where(Rider.id == rider_id)
    result = await db.execute(stmt)
    rider = result.scalar_one_or_none()
    if rider is not None:
        rider.trust_score = score
        await db.commit()

    return score
