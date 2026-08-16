"""
Unit tests for incident_service business logic.

Security tests:
- T-02: Users can only view their own incident reports.
- T-14: Rate limiting enforced (max 10 reports per user per hour).

Tests use mocked database sessions to isolate business logic
from database connectivity.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.models.incident_report import (
    IncidentReport,
    IncidentSeverity,
    IncidentStatus,
    ReportType,
)
from app.schemas.incident import IncidentReportCreate
from app.services.incident_router import (
    IncidentRouterBase,
    LogOnlyIncidentRouter,
    get_incident_router,
)
from app.services.incident_service import (
    IncidentNotFoundError,
    RateLimitExceededError,
    create_incident_report,
    get_incident_by_id,
    get_user_incidents,
)


def _make_mock_db() -> AsyncMock:
    """Create a mock AsyncSession."""
    db = AsyncMock()
    db.add = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    db.rollback = AsyncMock()
    return db


def _make_valid_create_data() -> IncidentReportCreate:
    """Create valid IncidentReportCreate data for testing."""
    return IncidentReportCreate(
        report_type=ReportType.suspicious_email,
        title="Suspicious email received",
        description="Received an email pretending to be from IT department asking to click a link.",
        occurred_at=datetime.now(UTC),
        severity=IncidentSeverity.medium,
        metadata_fields={"sender_or_url": "fake-it@evil.com"},
    )


def _make_mock_report(
    report_id: uuid.UUID | None = None,
    reporter_id: uuid.UUID | None = None,
) -> MagicMock:
    """Create a mock IncidentReport object."""
    report = MagicMock(spec=IncidentReport)
    report.id = report_id or uuid.uuid4()
    report.reporter_id = reporter_id or uuid.uuid4()
    report.report_type = ReportType.suspicious_email
    report.title = "Test Report"
    report.description = "Test description for incident."
    report.occurred_at = datetime.now(UTC)
    report.severity = IncidentSeverity.medium
    report.metadata_json = None
    report.status = IncidentStatus.submitted
    report.idempotency_key = None
    report.created_at = datetime.now(UTC)
    report.updated_at = datetime.now(UTC)
    return report


@pytest.mark.asyncio
class TestCreateIncidentReport:
    async def test_creates_report_with_valid_data(self) -> None:
        db = _make_mock_db()
        data = _make_valid_create_data()
        user_id = uuid.uuid4()

        # First call: rate limit count, returns 0
        count_result = MagicMock()
        count_result.scalar_one.return_value = 0
        db.execute.return_value = count_result

        report, is_new = await create_incident_report(user_id, data, db)

        assert is_new is True
        db.add.assert_called_once()
        db.commit.assert_awaited_once()
        db.refresh.assert_awaited_once()

    async def test_idempotency_key_replay_returns_existing(self) -> None:
        db = _make_mock_db()
        data = _make_valid_create_data()
        existing = _make_mock_report()
        existing.idempotency_key = "test-key-123"

        # First call: idempotency check returns existing report
        idem_result = MagicMock()
        idem_result.scalar_one_or_none.return_value = existing
        db.execute.return_value = idem_result

        report, is_new = await create_incident_report(
            uuid.uuid4(),
            data,
            db,
            idempotency_key="test-key-123",
        )

        assert report is existing
        assert is_new is False
        # Should not create a new report
        db.add.assert_not_called()
        db.commit.assert_not_awaited()

    async def test_rate_limit_raises_after_10_per_hour(self) -> None:
        db = _make_mock_db()
        data = _make_valid_create_data()

        # Rate limit count returns 10
        count_result = MagicMock()
        count_result.scalar_one.return_value = 10
        db.execute.return_value = count_result

        with pytest.raises(RateLimitExceededError):
            await create_incident_report(uuid.uuid4(), data, db)

    @patch("app.services.incident_service.get_incident_router")
    async def test_router_failure_does_not_block_creation(
        self,
        mock_get_router: MagicMock,
    ) -> None:
        db = _make_mock_db()
        data = _make_valid_create_data()

        # Rate limit passes
        count_result = MagicMock()
        count_result.scalar_one.return_value = 0
        db.execute.return_value = count_result

        # Router raises an exception
        mock_router = AsyncMock()
        mock_router.route.side_effect = RuntimeError("External service down")
        mock_get_router.return_value = mock_router

        report, is_new = await create_incident_report(uuid.uuid4(), data, db)

        assert is_new is True
        db.commit.assert_awaited_once()


@pytest.mark.asyncio
class TestGetUserIncidents:
    async def test_returns_own_reports_only(self) -> None:
        """T-02: get_user_incidents filters by reporter_id."""
        user_id = uuid.uuid4()
        db = _make_mock_db()

        mock_report = _make_mock_report(reporter_id=user_id)

        # First call: count, second call: list
        count_result = MagicMock()
        count_result.scalar_one.return_value = 1

        list_result = MagicMock()
        list_result.scalars.return_value.all.return_value = [mock_report]

        db.execute.side_effect = [count_result, list_result]

        records, total = await get_user_incidents(user_id, db)

        assert total == 1
        assert len(records) == 1
        assert records[0]["id"] == mock_report.id

    async def test_pagination(self) -> None:
        db = _make_mock_db()

        count_result = MagicMock()
        count_result.scalar_one.return_value = 25

        list_result = MagicMock()
        list_result.scalars.return_value.all.return_value = []

        db.execute.side_effect = [count_result, list_result]

        records, total = await get_user_incidents(
            uuid.uuid4(),
            db,
            page=2,
            page_size=10,
        )

        assert total == 25
        assert records == []

    async def test_returns_empty_when_no_reports(self) -> None:
        db = _make_mock_db()

        count_result = MagicMock()
        count_result.scalar_one.return_value = 0

        list_result = MagicMock()
        list_result.scalars.return_value.all.return_value = []

        db.execute.side_effect = [count_result, list_result]

        records, total = await get_user_incidents(uuid.uuid4(), db)

        assert total == 0
        assert records == []


@pytest.mark.asyncio
class TestGetIncidentById:
    async def test_returns_own_report(self) -> None:
        """T-02: Returns report when owned by the user."""
        user_id = uuid.uuid4()
        report = _make_mock_report(reporter_id=user_id)
        db = _make_mock_db()

        result = MagicMock()
        result.scalar_one_or_none.return_value = report
        db.execute.return_value = result

        returned = await get_incident_by_id(report.id, user_id, db)
        assert returned is report

    async def test_raises_for_other_user(self) -> None:
        """T-02: Raises IncidentNotFoundError when report belongs to another user."""
        db = _make_mock_db()

        result = MagicMock()
        result.scalar_one_or_none.return_value = None  # Not found for this user
        db.execute.return_value = result

        with pytest.raises(IncidentNotFoundError):
            await get_incident_by_id(uuid.uuid4(), uuid.uuid4(), db)

    async def test_raises_for_nonexistent_report(self) -> None:
        db = _make_mock_db()

        result = MagicMock()
        result.scalar_one_or_none.return_value = None
        db.execute.return_value = result

        with pytest.raises(IncidentNotFoundError):
            await get_incident_by_id(uuid.uuid4(), uuid.uuid4(), db)


class TestIncidentRouter:
    def test_log_only_router_is_subclass(self) -> None:
        router = LogOnlyIncidentRouter()
        assert isinstance(router, IncidentRouterBase)

    def test_router_interface_is_abstract(self) -> None:
        with pytest.raises(TypeError):
            IncidentRouterBase()  # type: ignore[abstract]

    def test_get_incident_router_returns_log_only(self) -> None:
        router = get_incident_router()
        assert isinstance(router, LogOnlyIncidentRouter)

    @pytest.mark.asyncio
    async def test_log_only_router_does_not_raise(self) -> None:
        router = LogOnlyIncidentRouter()
        report = _make_mock_report()
        # Should not raise
        await router.route(report)


class TestServiceExceptions:
    """Verify custom exception types exist and are properly structured."""

    def test_rate_limit_exceeded_error(self) -> None:
        with pytest.raises(RateLimitExceededError):
            raise RateLimitExceededError

    def test_incident_not_found_error(self) -> None:
        with pytest.raises(IncidentNotFoundError):
            raise IncidentNotFoundError
