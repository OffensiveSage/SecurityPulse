"""
Integration tests for incident report endpoints.

Security tests:
- T-02: Authorization — users can only view their own reports.
- T-11: Credential rejection — descriptions with passwords/MFA rejected.
- T-14: Rate limiting — max 10 reports per user per hour.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from unittest.mock import MagicMock, patch

import pytest
from pydantic import ValidationError

from app.models.incident_report import IncidentSeverity, ReportType
from app.schemas.incident import (
    IncidentReportCreate,
    IncidentReportCreated,
    IncidentReportSummary,
)


def _valid_body() -> dict:
    """Build a valid incident report request body."""
    return {
        "report_type": "suspicious_email",
        "title": "Phishing email received",
        "description": "Received an email pretending to be from HR asking to click a link.",
        "occurred_at": datetime.now(UTC).isoformat(),
        "severity": "medium",
        "metadata_fields": {"sender_or_url": "fake-hr@evil.com"},
    }


@pytest.mark.asyncio
class TestIncidentSchemas:
    """Unit tests for incident Pydantic schemas (no DB required)."""

    def test_valid_data_passes_validation(self) -> None:
        data = IncidentReportCreate(**_valid_body())
        assert data.report_type == ReportType.suspicious_email
        assert data.severity == IncidentSeverity.medium

    def test_short_title_rejected(self) -> None:
        body = _valid_body()
        body["title"] = "Ab"  # Too short (min 5)
        with pytest.raises(ValidationError):
            IncidentReportCreate(**body)

    def test_long_title_rejected(self) -> None:
        body = _valid_body()
        body["title"] = "A" * 101  # Too long (max 100)
        with pytest.raises(ValidationError):
            IncidentReportCreate(**body)

    def test_short_description_rejected(self) -> None:
        body = _valid_body()
        body["description"] = "Too short"  # 9 chars (min 10)
        with pytest.raises(ValidationError):
            IncidentReportCreate(**body)

    def test_future_date_rejected(self) -> None:
        body = _valid_body()
        body["occurred_at"] = (datetime.now(UTC) + timedelta(hours=2)).isoformat()
        with pytest.raises(ValidationError):
            IncidentReportCreate(**body)

    def test_credential_pattern_in_description_rejected(self) -> None:
        """T-11: Credential patterns in descriptions must be rejected."""
        body = _valid_body()
        body["description"] = "User reported that their password= MySecret123 was compromised"
        with pytest.raises(ValidationError, match="credentials"):
            IncidentReportCreate(**body)

    def test_forbidden_metadata_key_rejected(self) -> None:
        """T-11: Forbidden keys in metadata must be rejected."""
        body = _valid_body()
        body["metadata_fields"] = {"auth_token": "abc123"}
        with pytest.raises(ValidationError, match="Forbidden metadata"):
            IncidentReportCreate(**body)

    def test_invalid_metadata_keys_for_type_rejected(self) -> None:
        body = _valid_body()
        # suspicious_email only accepts sender_or_url
        body["metadata_fields"] = {"device_type": "laptop"}
        with pytest.raises(ValidationError, match="Unexpected metadata"):
            IncidentReportCreate(**body)

    def test_lost_device_metadata_accepted(self) -> None:
        body = _valid_body()
        body["report_type"] = "lost_device"
        body["metadata_fields"] = {
            "device_type": "laptop",
            "last_known_location": "Office 3B",
        }
        data = IncidentReportCreate(**body)
        assert data.metadata_fields is not None
        assert data.metadata_fields["device_type"] == "laptop"

    def test_data_exposure_metadata_accepted(self) -> None:
        body = _valid_body()
        body["report_type"] = "data_exposure"
        body["metadata_fields"] = {"data_classification": "confidential"}
        data = IncidentReportCreate(**body)
        assert data.metadata_fields is not None

    def test_response_created_shape(self) -> None:
        rid = uuid.uuid4()
        created = IncidentReportCreated(report_id=rid)
        assert created.report_id == rid

    def test_summary_shape(self) -> None:
        summary = IncidentReportSummary(
            id=uuid.uuid4(),
            report_type="suspicious_email",
            title="Test",
            severity="medium",
            status="submitted",
            created_at=datetime.now(UTC),
        )
        dumped = summary.model_dump()
        assert "id" in dumped
        assert "status" in dumped


@pytest.mark.asyncio
class TestCreateIncidentEndpoint:
    async def test_returns_401_without_token(self, client) -> None:
        response = await client.post(
            "/api/v1/incidents",
            json=_valid_body(),
        )
        assert response.status_code in (401, 422)

    @patch("app.api.v1.endpoints.incidents.create_incident_report")
    async def test_returns_201_on_valid_submission(
        self,
        mock_create,
        authed_client,
    ) -> None:
        report = MagicMock()
        report.id = uuid.uuid4()
        mock_create.return_value = (report, True)

        response = await authed_client.post(
            "/api/v1/incidents",
            json=_valid_body(),
        )
        assert response.status_code == 201
        data = response.json()
        assert "report_id" in data

    @patch("app.api.v1.endpoints.incidents.create_incident_report")
    async def test_returns_200_on_idempotent_replay(
        self,
        mock_create,
        authed_client,
    ) -> None:
        report = MagicMock()
        report.id = uuid.uuid4()
        mock_create.return_value = (report, False)

        response = await authed_client.post(
            "/api/v1/incidents",
            json=_valid_body(),
            headers={"Idempotency-Key": "test-key-123"},
        )
        assert response.status_code == 200
        data = response.json()
        assert "report_id" in data

    @patch("app.api.v1.endpoints.incidents.create_incident_report")
    async def test_returns_429_on_rate_limit(
        self,
        mock_create,
        authed_client,
    ) -> None:
        """T-14: Rate limit returns 429."""
        from app.services.incident_service import RateLimitExceededError

        mock_create.side_effect = RateLimitExceededError

        response = await authed_client.post(
            "/api/v1/incidents",
            json=_valid_body(),
        )
        assert response.status_code == 429


@pytest.mark.asyncio
class TestListMyIncidentsEndpoint:
    async def test_returns_401_without_token(self, client) -> None:
        response = await client.get("/api/v1/incidents/mine")
        assert response.status_code in (401, 422)

    @patch("app.api.v1.endpoints.incidents.get_user_incidents")
    async def test_returns_paginated_list(
        self,
        mock_get,
        authed_client,
    ) -> None:
        records = [
            {
                "id": uuid.uuid4(),
                "report_type": "suspicious_email",
                "title": "Test Report",
                "severity": "medium",
                "status": "submitted",
                "created_at": datetime.now(UTC),
            },
        ]
        mock_get.return_value = (records, 1)

        response = await authed_client.get("/api/v1/incidents/mine")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "meta" in data
        assert data["meta"]["total"] == 1
        assert len(data["data"]) == 1


@pytest.mark.asyncio
class TestGetIncidentEndpoint:
    async def test_returns_401_without_token(self, client) -> None:
        fake_id = uuid.uuid4()
        response = await client.get(f"/api/v1/incidents/{fake_id}")
        assert response.status_code in (401, 422)

    @patch("app.api.v1.endpoints.incidents.get_incident_by_id")
    async def test_returns_404_for_other_users_report(
        self,
        mock_get_by_id,
        authed_client,
    ) -> None:
        """T-02: Users cannot view another user's incident report."""
        from app.services.incident_service import IncidentNotFoundError

        mock_get_by_id.side_effect = IncidentNotFoundError

        fake_id = uuid.uuid4()
        response = await authed_client.get(f"/api/v1/incidents/{fake_id}")
        assert response.status_code == 404

    @patch("app.api.v1.endpoints.incidents.get_incident_by_id")
    async def test_returns_200_for_own_report(
        self,
        mock_get_by_id,
        authed_client,
    ) -> None:
        """T-02: Users can view their own report."""
        report = MagicMock()
        report.id = uuid.uuid4()
        report.report_type = ReportType.suspicious_email
        report.title = "Test Report"
        report.description = "Test description for the report."
        report.occurred_at = datetime.now(UTC)
        report.severity = IncidentSeverity.medium
        report.metadata_json = None
        report.status = MagicMock()
        report.status.value = "submitted"
        report.created_at = datetime.now(UTC)
        report.updated_at = datetime.now(UTC)

        mock_get_by_id.return_value = report

        response = await authed_client.get(
            f"/api/v1/incidents/{report.id}",
        )
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Test Report"
