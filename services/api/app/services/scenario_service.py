"""
Scenario service — business logic for daily scenario delivery.

Security enforcement:
- T-02: All queries filter by user_id to prevent horizontal escalation.
- T-03: Correct answers are never exposed before submission.
- T-04: Unique constraint + idempotency key prevents duplicate responses.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import structlog
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.assignment import Assignment
from app.models.response import Response, ResponseSource
from app.models.scenario import AnswerOption, Scenario, ScenarioStatus

logger = structlog.get_logger(__name__)


class ConflictError(Exception):
    """Raised when a duplicate response is submitted without an idempotency key."""


class ExpiredAssignmentError(Exception):
    """Raised when an assignment's due_at has passed."""


class NotAssignedError(Exception):
    """Raised when the user is not assigned to the requested scenario."""


class OptionNotFoundError(Exception):
    """Raised when the selected option does not belong to the scenario."""


class NoResponseExistsError(Exception):
    """Raised when requesting results before submitting a response."""


async def get_today_scenario_for_user(
    user_id: uuid.UUID,
    db: AsyncSession,
) -> Scenario | None:
    """Get the current active scenario assigned to the user.

    Returns the scenario with eagerly-loaded answer_options, or None if
    no active assignment exists for today.
    """
    now = datetime.now(UTC)
    stmt = (
        select(Scenario)
        .join(Assignment, Assignment.scenario_id == Scenario.id)
        .where(
            Assignment.user_id == user_id,
            Assignment.available_from <= now,
            Assignment.due_at > now,
            Scenario.status == ScenarioStatus.published,
        )
        .order_by(Assignment.available_from.desc())
        .limit(1)
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def get_scenario_by_id(
    scenario_id: uuid.UUID,
    user_id: uuid.UUID,
    db: AsyncSession,
) -> Scenario:
    """Get a scenario by ID, verifying the user has an assignment (T-02).

    Raises:
        NotAssignedError: If no assignment exists for this user+scenario.
    """
    stmt = (
        select(Scenario)
        .join(Assignment, Assignment.scenario_id == Scenario.id)
        .where(
            Scenario.id == scenario_id,
            Assignment.user_id == user_id,
            Scenario.status == ScenarioStatus.published,
        )
        .limit(1)
    )
    result = await db.execute(stmt)
    scenario = result.scalar_one_or_none()

    if scenario is None:
        raise NotAssignedError

    return scenario


async def submit_response(
    user_id: uuid.UUID,
    scenario_id: uuid.UUID,
    selected_option_id: uuid.UUID,
    db: AsyncSession,
    idempotency_key: str | None = None,
    response_time_ms: int | None = None,
    source: str | None = None,
) -> tuple[Response, bool]:
    """Submit a response to a scenario.

    Returns:
        Tuple of (response, is_new). is_new=False when replaying an idempotent request.

    Raises:
        NotAssignedError: No assignment for this user+scenario.
        ExpiredAssignmentError: Assignment has expired.
        OptionNotFoundError: Selected option does not belong to scenario.
        ConflictError: Duplicate submission without idempotency key.
    """
    # 1. Check idempotency key replay
    if idempotency_key:
        idem_stmt = select(Response).where(Response.idempotency_key == idempotency_key)
        idem_result = await db.execute(idem_stmt)
        existing = idem_result.scalar_one_or_none()
        if existing is not None:
            logger.info(
                "idempotent_replay",
                response_id=str(existing.id),
                key=idempotency_key,
            )
            return (existing, False)

    # 2. Verify assignment exists and is not expired
    now = datetime.now(UTC)
    assign_stmt = (
        select(Assignment)
        .where(
            Assignment.scenario_id == scenario_id,
            Assignment.user_id == user_id,
        )
        .limit(1)
    )
    assign_result = await db.execute(assign_stmt)
    assignment = assign_result.scalar_one_or_none()

    if assignment is None:
        raise NotAssignedError

    if assignment.due_at <= now:
        raise ExpiredAssignmentError

    # 3. Verify selected option belongs to the scenario
    option_stmt = select(AnswerOption).where(
        AnswerOption.id == selected_option_id,
        AnswerOption.scenario_id == scenario_id,
    )
    option_result = await db.execute(option_stmt)
    option = option_result.scalar_one_or_none()

    if option is None:
        raise OptionNotFoundError

    # 4. Determine correctness from the option
    is_correct = option.is_correct

    # 5. Build and persist the response
    response_source = ResponseSource.app
    if source == "widget":
        response_source = ResponseSource.widget

    response = Response(
        id=uuid.uuid4(),
        user_id=user_id,
        scenario_id=scenario_id,
        selected_option_id=selected_option_id,
        is_correct=is_correct,
        response_time_ms=response_time_ms,
        source=response_source,
        idempotency_key=idempotency_key,
    )

    db.add(response)
    try:
        await db.commit()
        await db.refresh(response)
    except IntegrityError as exc:
        await db.rollback()
        # The unique constraint uq_responses_user_scenario was violated
        raise ConflictError from exc

    logger.info(
        "response_submitted",
        response_id=str(response.id),
        user_id=str(user_id),
        scenario_id=str(scenario_id),
        is_correct=is_correct,
    )

    return (response, True)


async def get_scenario_result(
    user_id: uuid.UUID,
    scenario_id: uuid.UUID,
    db: AsyncSession,
) -> dict[str, Any]:
    """Get the result of a scenario after the user has submitted a response (T-03).

    Returns a dict with scenario_id, selected_option_id, is_correct,
    explanation, recommended_action, and answer_options (with correctness).

    Raises:
        NoResponseExistsError: If the user has not submitted a response.
        NotAssignedError: If the scenario does not exist or is not assigned.
    """
    # Verify response exists (T-03: results only shown after submission)
    resp_stmt = select(Response).where(
        Response.user_id == user_id,
        Response.scenario_id == scenario_id,
    )
    resp_result = await db.execute(resp_stmt)
    response = resp_result.scalar_one_or_none()

    if response is None:
        raise NoResponseExistsError

    # Get the scenario with answer options
    scenario_stmt = select(Scenario).where(Scenario.id == scenario_id)
    scenario_result = await db.execute(scenario_stmt)
    scenario = scenario_result.scalar_one_or_none()

    if scenario is None:
        raise NotAssignedError

    return {
        "scenario_id": scenario.id,
        "selected_option_id": response.selected_option_id,
        "is_correct": response.is_correct,
        "explanation": scenario.explanation,
        "recommended_action": scenario.recommended_action,
        "answer_options": [
            {
                "id": opt.id,
                "text": opt.text,
                "is_correct": opt.is_correct,
                "display_order": opt.display_order,
            }
            for opt in scenario.answer_options
        ],
    }


async def get_response_history(
    user_id: uuid.UUID,
    db: AsyncSession,
    page: int = 1,
    page_size: int = 20,
) -> tuple[list[dict[str, Any]], int]:
    """Get paginated response history for a user, most recent first.

    Returns:
        Tuple of (list of response dicts, total count).
    """
    # Count total
    count_stmt = select(func.count()).select_from(Response).where(Response.user_id == user_id)
    total = (await db.execute(count_stmt)).scalar_one()

    # Fetch page
    offset = (page - 1) * page_size
    history_stmt = (
        select(Response, Scenario.title)
        .join(Scenario, Response.scenario_id == Scenario.id)
        .where(Response.user_id == user_id)
        .order_by(Response.submitted_at.desc())
        .offset(offset)
        .limit(page_size)
    )
    history_result = await db.execute(history_stmt)
    rows = history_result.all()

    records = [
        {
            "id": row.Response.id,
            "scenario_id": row.Response.scenario_id,
            "scenario_title": row.title,
            "submitted_at": row.Response.submitted_at,
            "is_correct": row.Response.is_correct,
        }
        for row in rows
    ]

    return (records, total)


async def get_user_progress(
    user_id: uuid.UUID,
    db: AsyncSession,
) -> dict[str, Any]:
    """Get progress summary for a user.

    Returns dict with scenarios_assigned, scenarios_completed,
    current_streak_days.
    """
    # Count assigned scenarios
    assigned_stmt = (
        select(func.count()).select_from(Assignment).where(Assignment.user_id == user_id)
    )
    scenarios_assigned = (await db.execute(assigned_stmt)).scalar_one()

    # Count completed (responded) scenarios
    completed_stmt = select(func.count()).select_from(Response).where(Response.user_id == user_id)
    scenarios_completed = (await db.execute(completed_stmt)).scalar_one()

    # Calculate streak: consecutive days with a response
    streak = await _calculate_streak(user_id, db)

    return {
        "scenarios_assigned": scenarios_assigned,
        "scenarios_completed": scenarios_completed,
        "current_streak_days": streak,
    }


async def _calculate_streak(
    user_id: uuid.UUID,
    db: AsyncSession,
) -> int:
    """Calculate the current streak of consecutive days with a response."""
    # Get distinct response dates, most recent first
    stmt = (
        select(func.date(Response.submitted_at).label("response_date"))
        .where(Response.user_id == user_id)
        .group_by(func.date(Response.submitted_at))
        .order_by(func.date(Response.submitted_at).desc())
    )
    result = await db.execute(stmt)
    dates = [row.response_date for row in result.all()]

    if not dates:
        return 0

    today = datetime.now(UTC).date()
    streak = 0

    # Streak must include today or yesterday to be current
    if dates[0] != today and dates[0] != today - timedelta(days=1):
        return 0

    expected_date = dates[0]
    for d in dates:
        if d == expected_date:
            streak += 1
            expected_date = d - timedelta(days=1)
        else:
            break

    return streak
