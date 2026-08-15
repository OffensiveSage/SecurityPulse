"""
Unit tests for scenario_service business logic.

Tests use mocked database sessions to isolate business logic
from database connectivity.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.models.assignment import Assignment
from app.models.response import Response
from app.models.scenario import (
    AnswerOption,
    Scenario,
    ScenarioCategory,
    ScenarioDifficulty,
    ScenarioStatus,
)
from app.services.scenario_service import (
    ConflictError,
    ExpiredAssignmentError,
    NoResponseExistsError,
    NotAssignedError,
    OptionNotFoundError,
    get_scenario_by_id,
    get_scenario_result,
    get_today_scenario_for_user,
    get_user_progress,
    submit_response,
)


def _make_scenario(
    scenario_id: uuid.UUID | None = None,
    status: ScenarioStatus = ScenarioStatus.published,
) -> Scenario:
    """Create a mock Scenario object."""
    sid = scenario_id or uuid.uuid4()
    scenario = MagicMock(spec=Scenario)
    scenario.id = sid
    scenario.title = "Test Scenario"
    scenario.prompt = "Test prompt"
    scenario.category = ScenarioCategory.phishing
    scenario.difficulty = ScenarioDifficulty.beginner
    scenario.status = status
    scenario.explanation = "Test explanation"
    scenario.recommended_action = "Test action"

    opt1 = MagicMock(spec=AnswerOption)
    opt1.id = uuid.uuid4()
    opt1.text = "Option 1"
    opt1.is_correct = False
    opt1.display_order = 0

    opt2 = MagicMock(spec=AnswerOption)
    opt2.id = uuid.uuid4()
    opt2.text = "Option 2"
    opt2.is_correct = True
    opt2.display_order = 1

    scenario.answer_options = [opt1, opt2]
    return scenario


def _make_assignment(
    scenario_id: uuid.UUID,
    user_id: uuid.UUID,
    due_at: datetime | None = None,
) -> Assignment:
    """Create a mock Assignment object."""
    assignment = MagicMock(spec=Assignment)
    assignment.id = uuid.uuid4()
    assignment.scenario_id = scenario_id
    assignment.user_id = user_id
    assignment.available_from = datetime.now(UTC) - timedelta(hours=1)
    assignment.due_at = due_at or (datetime.now(UTC) + timedelta(hours=23))
    return assignment


def _make_mock_db() -> AsyncMock:
    """Create a mock AsyncSession."""
    db = AsyncMock()
    db.add = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    db.rollback = AsyncMock()
    return db


def _setup_db_result(db: AsyncMock, return_value: object) -> None:
    """Configure the mock DB to return a specific result."""
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = return_value
    db.execute.return_value = mock_result


@pytest.mark.asyncio
class TestGetTodayScenarioForUser:
    async def test_returns_scenario_when_assignment_exists(self) -> None:
        scenario = _make_scenario()
        db = _make_mock_db()
        _setup_db_result(db, scenario)

        result = await get_today_scenario_for_user(uuid.uuid4(), db)
        assert result is scenario

    async def test_returns_none_when_no_assignment(self) -> None:
        db = _make_mock_db()
        _setup_db_result(db, None)

        result = await get_today_scenario_for_user(uuid.uuid4(), db)
        assert result is None


@pytest.mark.asyncio
class TestGetScenarioById:
    async def test_returns_scenario_when_assigned(self) -> None:
        scenario = _make_scenario()
        db = _make_mock_db()
        _setup_db_result(db, scenario)

        result = await get_scenario_by_id(scenario.id, uuid.uuid4(), db)
        assert result is scenario

    async def test_raises_not_assigned_when_no_assignment(self) -> None:
        db = _make_mock_db()
        _setup_db_result(db, None)

        with pytest.raises(NotAssignedError):
            await get_scenario_by_id(uuid.uuid4(), uuid.uuid4(), db)


@pytest.mark.asyncio
class TestSubmitResponse:
    async def test_raises_not_assigned_when_no_assignment(self) -> None:
        db = _make_mock_db()
        # No idempotency_key → first call is assignment check returns None
        result = MagicMock()
        result.scalar_one_or_none.return_value = None
        db.execute.return_value = result

        with pytest.raises(NotAssignedError):
            await submit_response(
                user_id=uuid.uuid4(),
                scenario_id=uuid.uuid4(),
                selected_option_id=uuid.uuid4(),
                db=db,
            )

    async def test_raises_expired_when_assignment_past_due(self) -> None:
        scenario_id = uuid.uuid4()
        user_id = uuid.uuid4()
        assignment = _make_assignment(
            scenario_id,
            user_id,
            due_at=datetime.now(UTC) - timedelta(hours=1),
        )

        db = _make_mock_db()
        # No idempotency_key → no idempotency check → first call is assignment
        result = MagicMock()
        result.scalar_one_or_none.return_value = assignment
        db.execute.return_value = result

        with pytest.raises(ExpiredAssignmentError):
            await submit_response(
                user_id=user_id,
                scenario_id=scenario_id,
                selected_option_id=uuid.uuid4(),
                db=db,
            )

    async def test_raises_option_not_found_when_invalid_option(self) -> None:
        scenario_id = uuid.uuid4()
        user_id = uuid.uuid4()
        assignment = _make_assignment(scenario_id, user_id)

        db = _make_mock_db()
        # No idempotency_key → first call is assignment, second is option check
        results = [MagicMock(), MagicMock()]
        results[0].scalar_one_or_none.return_value = assignment
        results[1].scalar_one_or_none.return_value = None  # Option not found
        db.execute.side_effect = results

        with pytest.raises(OptionNotFoundError):
            await submit_response(
                user_id=user_id,
                scenario_id=scenario_id,
                selected_option_id=uuid.uuid4(),
                db=db,
            )

    async def test_returns_existing_response_on_idempotent_replay(self) -> None:
        existing_response = MagicMock(spec=Response)
        existing_response.id = uuid.uuid4()

        db = _make_mock_db()
        result = MagicMock()
        result.scalar_one_or_none.return_value = existing_response
        db.execute.return_value = result

        response, is_new = await submit_response(
            user_id=uuid.uuid4(),
            scenario_id=uuid.uuid4(),
            selected_option_id=uuid.uuid4(),
            db=db,
            idempotency_key="test-key-123",
        )
        assert response is existing_response
        assert is_new is False


@pytest.mark.asyncio
class TestGetScenarioResult:
    async def test_raises_no_response_when_not_submitted(self) -> None:
        db = _make_mock_db()
        _setup_db_result(db, None)

        with pytest.raises(NoResponseExistsError):
            await get_scenario_result(uuid.uuid4(), uuid.uuid4(), db)

    async def test_returns_result_when_response_exists(self) -> None:
        scenario = _make_scenario()
        response_obj = MagicMock(spec=Response)
        response_obj.selected_option_id = scenario.answer_options[1].id
        response_obj.is_correct = True

        db = _make_mock_db()
        # First call: get response
        # Second call: get scenario
        results = [MagicMock(), MagicMock()]
        results[0].scalar_one_or_none.return_value = response_obj
        results[1].scalar_one_or_none.return_value = scenario
        db.execute.side_effect = results

        result = await get_scenario_result(uuid.uuid4(), scenario.id, db)
        assert result["is_correct"] is True
        assert result["explanation"] == "Test explanation"
        assert len(result["answer_options"]) == 2


@pytest.mark.asyncio
class TestGetUserProgress:
    async def test_returns_zero_state(self) -> None:
        db = _make_mock_db()
        # Three sequential calls: assigned count, completed count, streak dates
        results = [MagicMock(), MagicMock(), MagicMock()]
        results[0].scalar_one.return_value = 0
        results[1].scalar_one.return_value = 0
        results[2].all.return_value = []
        db.execute.side_effect = results

        progress = await get_user_progress(uuid.uuid4(), db)
        assert progress["scenarios_assigned"] == 0
        assert progress["scenarios_completed"] == 0
        assert progress["current_streak_days"] == 0

    async def test_counts_assignments_and_completions(self) -> None:
        db = _make_mock_db()
        results = [MagicMock(), MagicMock(), MagicMock()]
        results[0].scalar_one.return_value = 5
        results[1].scalar_one.return_value = 3
        results[2].all.return_value = []
        db.execute.side_effect = results

        progress = await get_user_progress(uuid.uuid4(), db)
        assert progress["scenarios_assigned"] == 5
        assert progress["scenarios_completed"] == 3


class TestServiceExceptions:
    """Verify custom exception types exist and are properly structured."""

    def test_conflict_error(self) -> None:
        with pytest.raises(ConflictError):
            raise ConflictError

    def test_expired_assignment_error(self) -> None:
        with pytest.raises(ExpiredAssignmentError):
            raise ExpiredAssignmentError

    def test_not_assigned_error(self) -> None:
        with pytest.raises(NotAssignedError):
            raise NotAssignedError

    def test_option_not_found_error(self) -> None:
        with pytest.raises(OptionNotFoundError):
            raise OptionNotFoundError

    def test_no_response_exists_error(self) -> None:
        with pytest.raises(NoResponseExistsError):
            raise NoResponseExistsError
