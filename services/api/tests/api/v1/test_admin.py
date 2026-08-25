"""
Integration tests for /admin endpoints (Phase 6).

Tests analytics, campaigns, campaign eligibility, and audit events.
Uses dependency overrides for auth and DB so tests run without PostgreSQL.

Security tests:
- Employees (non-admin roles) must receive 403 on all admin endpoints.
- Analytics never returns individual-level data.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from app.api.dependencies.auth import get_current_user
from app.core.database import get_db_session
from app.models.user import User, UserRole, UserStatus
from app.schemas.admin import (
    AnalyticsSummary,
    CampaignSchema,
    EligibilityResult,
)
from app.schemas.common import PaginatedResponse, PaginationMeta


def _make_admin_user(role: UserRole = UserRole.platform_admin) -> User:
    """Create a mock admin user for dependency overrides."""
    user = MagicMock(spec=User)
    user.id = uuid.UUID("00000000-0000-0000-0000-000000000002")
    user.identity_provider_subject = f"mock-{role.value}-001"
    user.email = f"{role.value}@example.corp"
    user.display_name = f"Test {role.value.replace('_', ' ').title()}"
    user.role = role
    user.status = UserStatus.active
    user.department = None
    user.region = None
    return user


def _make_mock_db() -> AsyncMock:
    db = AsyncMock()
    db.add = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    db.rollback = AsyncMock()
    return db


@pytest.fixture
def admin_user() -> User:
    return _make_admin_user(UserRole.platform_admin)


@pytest.fixture
def approver_user() -> User:
    return _make_admin_user(UserRole.approver)


@pytest.fixture
def security_admin_user() -> User:
    return _make_admin_user(UserRole.security_admin)


@pytest.fixture
def employee_user() -> User:
    user = MagicMock(spec=User)
    user.id = uuid.UUID("00000000-0000-0000-0000-000000000003")
    user.identity_provider_subject = "mock-employee-001"
    user.email = "employee@example.corp"
    user.display_name = "Test Employee"
    user.role = UserRole.employee
    user.status = UserStatus.active
    user.department = None
    user.region = None
    return user


@pytest.fixture
def mock_db() -> AsyncMock:
    return _make_mock_db()


@pytest.fixture
def app():
    import os
    os.environ.setdefault("ALLOW_MOCK_AUTH", "true")
    os.environ.setdefault("APP_ENV", "development")
    from app.main import create_application
    return create_application()


@pytest.fixture
async def admin_client(app, admin_user, mock_db):
    """Client authenticated as platform_admin."""
    app.dependency_overrides[get_current_user] = lambda: admin_user
    app.dependency_overrides[get_db_session] = lambda: mock_db
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest.fixture
async def approver_client(app, approver_user, mock_db):
    """Client authenticated as approver."""
    app.dependency_overrides[get_current_user] = lambda: approver_user
    app.dependency_overrides[get_db_session] = lambda: mock_db
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest.fixture
async def employee_client(app, employee_user, mock_db):
    """Client authenticated as employee (non-admin)."""
    app.dependency_overrides[get_current_user] = lambda: employee_user
    app.dependency_overrides[get_db_session] = lambda: mock_db
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac
    app.dependency_overrides.clear()


# ─── Analytics tests ──────────────────────────────────────────────────────────

@pytest.mark.asyncio
class TestAnalyticsSummaryEndpoint:
    @patch("app.api.v1.endpoints.admin.analytics_service.get_analytics_summary")
    @patch("app.api.v1.endpoints.admin.persist_audit_event")
    async def test_returns_200_with_correct_schema_for_admin(
        self,
        mock_audit,
        mock_get_summary,
        admin_client,
    ) -> None:
        """GET /admin/analytics/summary returns 200 with AnalyticsSummary shape."""
        mock_audit.return_value = None
        mock_get_summary.return_value = AnalyticsSummary(
            total_employees_active=100,
            total_responses=500,
            overall_accuracy_rate=0.75,
            participation_rate=0.80,
            by_category=None,
            suppression_applied=False,
        )

        response = await admin_client.get("/api/v1/admin/analytics/summary")

        assert response.status_code == 200
        data = response.json()
        assert data["total_employees_active"] == 100
        assert data["total_responses"] == 500
        assert data["overall_accuracy_rate"] == 0.75
        assert data["participation_rate"] == 0.80
        assert "suppression_applied" in data

    @patch("app.api.v1.endpoints.admin.analytics_service.get_analytics_summary")
    @patch("app.api.v1.endpoints.admin.persist_audit_event")
    async def test_suppression_flag_visible_in_response(
        self,
        mock_audit,
        mock_get_summary,
        admin_client,
    ) -> None:
        """suppression_applied=True is surfaced when groups are below threshold."""
        mock_audit.return_value = None
        mock_get_summary.return_value = AnalyticsSummary(
            total_employees_active=10,
            total_responses=3,
            overall_accuracy_rate=0.67,
            participation_rate=0.30,
            suppression_applied=True,
        )

        response = await admin_client.get("/api/v1/admin/analytics/summary")
        assert response.status_code == 200
        assert response.json()["suppression_applied"] is True

    async def test_returns_403_for_employee(self, employee_client) -> None:
        """Employees must not access analytics endpoints."""
        response = await employee_client.get("/api/v1/admin/analytics/summary")
        assert response.status_code == 403

    @patch("app.api.v1.endpoints.admin.analytics_service.get_analytics_summary")
    @patch("app.api.v1.endpoints.admin.persist_audit_event")
    async def test_audit_event_is_persisted_on_access(
        self,
        mock_audit,
        mock_get_summary,
        admin_client,
    ) -> None:
        """Accessing analytics must write an audit event."""
        mock_audit.return_value = None
        mock_get_summary.return_value = AnalyticsSummary(
            total_employees_active=0,
            total_responses=0,
            overall_accuracy_rate=0.0,
            participation_rate=0.0,
        )

        await admin_client.get("/api/v1/admin/analytics/summary")
        mock_audit.assert_called_once()
        call_kwargs = mock_audit.call_args.kwargs
        assert call_kwargs["action"] == "analytics.export_downloaded"


# ─── Campaign list tests ───────────────────────────────────────────────────────

@pytest.mark.asyncio
class TestListCampaignsEndpoint:
    @patch("app.api.v1.endpoints.admin.campaign_service.list_campaigns")
    async def test_returns_200_with_paginated_list(
        self, mock_list, admin_client
    ) -> None:
        """GET /admin/campaigns returns 200 with PaginatedResponse shape."""
        campaign_id = uuid.uuid4()
        mock_list.return_value = PaginatedResponse[CampaignSchema](
            data=[
                CampaignSchema(
                    id=campaign_id,
                    name="Q3 Phishing Awareness",
                    status="draft",
                    start_at=datetime(2026, 9, 1, tzinfo=UTC),
                    end_at=datetime(2026, 9, 30, tzinfo=UTC),
                    eligibility_rule='{"min_responses": 5}',
                    reward_description="$50 gift card",
                    governance_disclaimer=(
                        "Final winner selection and prize fulfillment require approval "
                        "from HR, Legal, Tax, and Ethics. This eligibility count is for "
                        "planning purposes only."
                    ),
                )
            ],
            meta=PaginationMeta(page=1, page_size=20, total=1, total_pages=1),
        )

        response = await admin_client.get("/api/v1/admin/campaigns")

        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "meta" in data
        assert len(data["data"]) == 1
        assert data["data"][0]["name"] == "Q3 Phishing Awareness"
        assert "governance_disclaimer" in data["data"][0]

    async def test_returns_403_for_employee(self, employee_client) -> None:
        response = await employee_client.get("/api/v1/admin/campaigns")
        assert response.status_code == 403

    @patch("app.api.v1.endpoints.admin.campaign_service.list_campaigns")
    async def test_returns_empty_list_when_no_campaigns(
        self, mock_list, admin_client
    ) -> None:
        mock_list.return_value = PaginatedResponse[CampaignSchema](
            data=[],
            meta=PaginationMeta(page=1, page_size=20, total=0, total_pages=1),
        )

        response = await admin_client.get("/api/v1/admin/campaigns")
        assert response.status_code == 200
        assert response.json()["data"] == []


# ─── Campaign create tests ─────────────────────────────────────────────────────

@pytest.mark.asyncio
class TestCreateCampaignEndpoint:
    @patch("app.api.v1.endpoints.admin.campaign_service.create_campaign")
    @patch("app.api.v1.endpoints.admin.persist_audit_event")
    async def test_returns_201_with_created_campaign(
        self, mock_audit, mock_create, admin_client
    ) -> None:
        """POST /admin/campaigns returns 201 with the created CampaignSchema."""
        campaign_id = uuid.uuid4()
        mock_audit.return_value = None
        mock_create.return_value = CampaignSchema(
            id=campaign_id,
            name="New Campaign",
            status="draft",
            start_at=datetime(2026, 10, 1, tzinfo=UTC),
            end_at=datetime(2026, 10, 31, tzinfo=UTC),
            eligibility_rule='{"min_responses": 3}',
            reward_description=None,
            governance_disclaimer=(
                "Final winner selection and prize fulfillment require approval "
                "from HR, Legal, Tax, and Ethics. This eligibility count is for "
                "planning purposes only."
            ),
        )

        payload = {
            "name": "New Campaign",
            "start_at": "2026-10-01T00:00:00Z",
            "end_at": "2026-10-31T00:00:00Z",
            "eligibility_rule": '{"min_responses": 3}',
        }
        response = await admin_client.post("/api/v1/admin/campaigns", json=payload)

        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "New Campaign"
        assert data["status"] == "draft"
        assert "governance_disclaimer" in data

    @patch("app.api.v1.endpoints.admin.campaign_service.create_campaign")
    @patch("app.api.v1.endpoints.admin.persist_audit_event")
    async def test_audit_event_written_on_create(
        self, mock_audit, mock_create, admin_client
    ) -> None:
        campaign_id = uuid.uuid4()
        mock_audit.return_value = None
        mock_create.return_value = CampaignSchema(
            id=campaign_id,
            name="Audit Test",
            status="draft",
            start_at=datetime(2026, 11, 1, tzinfo=UTC),
            end_at=datetime(2026, 11, 30, tzinfo=UTC),
            eligibility_rule='{}',
            reward_description=None,
            governance_disclaimer="disclaimer",
        )

        payload = {
            "name": "Audit Test",
            "start_at": "2026-11-01T00:00:00Z",
            "end_at": "2026-11-30T00:00:00Z",
            "eligibility_rule": "{}",
        }
        await admin_client.post("/api/v1/admin/campaigns", json=payload)

        mock_audit.assert_called()
        call_kwargs = mock_audit.call_args.kwargs
        assert call_kwargs["action"] == "campaign.created"

    async def test_returns_403_for_employee(self, employee_client) -> None:
        payload = {
            "name": "Blocked",
            "start_at": "2026-10-01T00:00:00Z",
            "end_at": "2026-10-31T00:00:00Z",
            "eligibility_rule": '{}',
        }
        response = await employee_client.post("/api/v1/admin/campaigns", json=payload)
        assert response.status_code == 403

    async def test_returns_422_when_name_is_empty(self, admin_client) -> None:
        payload = {
            "name": "",
            "start_at": "2026-10-01T00:00:00Z",
            "end_at": "2026-10-31T00:00:00Z",
            "eligibility_rule": '{}',
        }
        response = await admin_client.post("/api/v1/admin/campaigns", json=payload)
        assert response.status_code == 422


# ─── Campaign eligibility tests ────────────────────────────────────────────────

@pytest.mark.asyncio
class TestCalculateEligibilityEndpoint:
    @patch("app.api.v1.endpoints.admin.campaign_service.calculate_eligibility")
    @patch("app.api.v1.endpoints.admin.persist_audit_event")
    async def test_returns_200_with_eligibility_result(
        self, mock_audit, mock_calc, admin_client
    ) -> None:
        """POST /.../calculate-eligibility returns 200 with EligibilityResult."""
        campaign_id = uuid.uuid4()
        mock_audit.return_value = None
        mock_calc.return_value = EligibilityResult(
            eligible_count=42,
            calculated_at=datetime.now(UTC),
            suppressed=False,
        )

        response = await admin_client.post(
            f"/api/v1/admin/campaigns/{campaign_id}/calculate-eligibility"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["eligible_count"] == 42
        assert data["suppressed"] is False
        assert "calculated_at" in data

    @patch("app.api.v1.endpoints.admin.campaign_service.calculate_eligibility")
    @patch("app.api.v1.endpoints.admin.persist_audit_event")
    async def test_returns_suppressed_result_when_count_below_threshold(
        self, mock_audit, mock_calc, admin_client
    ) -> None:
        """Eligible count is zeroed and suppressed=True when below threshold."""
        campaign_id = uuid.uuid4()
        mock_audit.return_value = None
        mock_calc.return_value = EligibilityResult(
            eligible_count=0,
            calculated_at=datetime.now(UTC),
            suppressed=True,
        )

        response = await admin_client.post(
            f"/api/v1/admin/campaigns/{campaign_id}/calculate-eligibility"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["suppressed"] is True
        assert data["eligible_count"] == 0

    @patch("app.api.v1.endpoints.admin.campaign_service.calculate_eligibility")
    @patch("app.api.v1.endpoints.admin.persist_audit_event")
    async def test_returns_404_when_campaign_not_found(
        self, mock_audit, mock_calc, admin_client
    ) -> None:
        campaign_id = uuid.uuid4()
        mock_audit.return_value = None
        mock_calc.side_effect = ValueError(f"Campaign {campaign_id} not found")

        response = await admin_client.post(
            f"/api/v1/admin/campaigns/{campaign_id}/calculate-eligibility"
        )
        assert response.status_code == 404

    async def test_returns_403_for_employee(self, employee_client) -> None:
        campaign_id = uuid.uuid4()
        response = await employee_client.post(
            f"/api/v1/admin/campaigns/{campaign_id}/calculate-eligibility"
        )
        assert response.status_code == 403


# ─── Audit events tests ────────────────────────────────────────────────────────

@pytest.mark.asyncio
class TestListAuditEventsEndpoint:
    @patch("app.api.v1.endpoints.admin.persist_audit_event")
    async def test_returns_200_with_paginated_audit_events(
        self, mock_audit, admin_client, mock_db
    ) -> None:
        """GET /admin/audit-events returns 200 with PaginatedResponse shape."""
        mock_audit.return_value = None

        # Mock the DB query results for audit events listing
        event_id = uuid.uuid4()
        actor_id = uuid.uuid4()
        mock_event = MagicMock()
        mock_event.id = event_id
        mock_event.actor_id = actor_id
        mock_event.action = "campaign.created"
        mock_event.target_type = "campaign"
        mock_event.target_id = str(uuid.uuid4())
        mock_event.before_summary = None
        mock_event.after_summary = "name=Test"
        mock_event.timestamp = datetime.now(UTC)
        mock_event.correlation_id = None

        # Simulate db.execute returning a count then rows
        mock_count_result = MagicMock()
        mock_count_result.scalar_one.return_value = 1
        mock_rows_result = MagicMock()
        mock_rows_result.scalars.return_value.all.return_value = [mock_event]

        call_count = 0

        async def fake_execute(stmt):
            nonlocal call_count
            call_count += 1
            # First call after the audit persist is the count query
            if call_count == 1:
                return mock_count_result
            return mock_rows_result

        mock_db.execute = fake_execute

        response = await admin_client.get("/api/v1/admin/audit-events")

        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "meta" in data

    async def test_returns_403_for_employee(self, employee_client) -> None:
        """Employees must not access audit events."""
        response = await employee_client.get("/api/v1/admin/audit-events")
        assert response.status_code == 403

    @patch("app.api.v1.endpoints.admin.persist_audit_event")
    async def test_audit_access_itself_is_logged(
        self, mock_audit, admin_client, mock_db
    ) -> None:
        """Accessing audit events must itself create an audit log entry."""
        mock_audit.return_value = None

        mock_count_result = MagicMock()
        mock_count_result.scalar_one.return_value = 0
        mock_rows_result = MagicMock()
        mock_rows_result.scalars.return_value.all.return_value = []

        call_count = 0

        async def fake_execute(stmt):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                return mock_count_result
            return mock_rows_result

        mock_db.execute = fake_execute

        await admin_client.get("/api/v1/admin/audit-events")

        mock_audit.assert_called_once()
        call_kwargs = mock_audit.call_args.kwargs
        assert call_kwargs["action"] == "audit_events.accessed"

    async def test_validates_page_must_be_positive(self, admin_client) -> None:
        response = await admin_client.get(
            "/api/v1/admin/audit-events", params={"page": 0}
        )
        assert response.status_code == 422
