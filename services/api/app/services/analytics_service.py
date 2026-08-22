"""Aggregated analytics service. Never returns individual-level data."""

from __future__ import annotations

import uuid

from sqlalchemy import Integer, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.response import Response
from app.models.scenario import Scenario
from app.models.user import User, UserStatus
from app.schemas.admin import AnalyticsSummary, CategoryAccuracy, MIN_ANALYTICS_GROUP_SIZE


async def get_analytics_summary(db: AsyncSession) -> AnalyticsSummary:
    """Return aggregated analytics. Suppresses categories below MIN_ANALYTICS_GROUP_SIZE."""
    # Total active employees
    active_stmt = select(func.count()).select_from(User).where(User.status == UserStatus.active)
    total_employees_active = (await db.execute(active_stmt)).scalar_one()

    # Total responses
    resp_stmt = select(func.count()).select_from(Response)
    total_responses = (await db.execute(resp_stmt)).scalar_one()

    # Overall accuracy rate
    correct_stmt = (
        select(func.count()).select_from(Response).where(Response.is_correct == True)  # noqa: E712
    )
    total_correct = (await db.execute(correct_stmt)).scalar_one()
    overall_accuracy_rate = (total_correct / total_responses) if total_responses > 0 else 0.0

    # Participation rate (users who responded / total active)
    responded_stmt = select(func.count(func.distinct(Response.user_id))).select_from(Response)
    users_responded = (await db.execute(responded_stmt)).scalar_one()
    participation_rate = (
        (users_responded / total_employees_active) if total_employees_active > 0 else 0.0
    )

    # By category: count responses and correct responses per scenario category
    cat_stmt = (
        select(
            Scenario.category,
            func.count(Response.id).label("response_count"),
            func.sum(Response.is_correct.cast(Integer)).label("correct_count"),
        )
        .join(Scenario, Response.scenario_id == Scenario.id)
        .group_by(Scenario.category)
    )
    cat_rows = (await db.execute(cat_stmt)).all()

    by_category: list[CategoryAccuracy] = []
    suppression_applied = False
    for row in cat_rows:
        count = row.response_count or 0
        correct = row.correct_count or 0
        if count < MIN_ANALYTICS_GROUP_SIZE:
            suppression_applied = True
            by_category.append(
                CategoryAccuracy(
                    category=row.category,
                    response_count=count,
                    accuracy_rate=0.0,
                    suppressed=True,
                )
            )
        else:
            by_category.append(
                CategoryAccuracy(
                    category=row.category,
                    response_count=count,
                    accuracy_rate=correct / count,
                    suppressed=False,
                )
            )

    return AnalyticsSummary(
        total_employees_active=total_employees_active,
        total_responses=total_responses,
        overall_accuracy_rate=overall_accuracy_rate,
        participation_rate=participation_rate,
        by_category=by_category if by_category else None,
        suppression_applied=suppression_applied,
    )
