"""
Integration tests for scenario endpoints.

Security tests:
- T-02: Authorization — users can only access assigned scenarios.
- T-03: Answer leakage — is_correct never in pre-submission responses.
- T-04: Idempotency — duplicate submissions handled correctly.
"""

from __future__ import annotations

import uuid
from unittest.mock import MagicMock, patch

import pytest

from app.schemas.scenario import (
    AnswerOptionForEmployee,
    AnswerOptionWithResult,
    ResponseCreated,
    ScenarioForEmployee,
    ScenarioResultResponse,
)


@pytest.mark.asyncio
class TestScenarioSchemas:
    """Unit tests for Pydantic schemas (no DB required)."""

    def test_scenario_for_employee_excludes_is_correct(self) -> None:
        """T-03: ScenarioForEmployee must never contain is_correct."""
        schema = ScenarioForEmployee(
            id=uuid.uuid4(),
            title="Test Scenario",
            prompt="Test prompt",
            category="phishing",
            difficulty="beginner",
            answer_options=[
                AnswerOptionForEmployee(
                    id=uuid.uuid4(),
                    text="Option 1",
                    display_order=0,
                ),
            ],
        )
        dumped = schema.model_dump()
        # is_correct must not appear anywhere in the serialized output
        assert "is_correct" not in str(dumped)
        for opt in dumped["answer_options"]:
            assert "is_correct" not in opt

    def test_answer_option_for_employee_has_no_is_correct_field(self) -> None:
        """T-03: AnswerOptionForEmployee schema must not have is_correct field."""
        fields = AnswerOptionForEmployee.model_fields
        assert "is_correct" not in fields

    def test_answer_option_with_result_has_is_correct_field(self) -> None:
        """Post-submission schema includes is_correct."""
        fields = AnswerOptionWithResult.model_fields
        assert "is_correct" in fields

    def test_scenario_result_response_shape(self) -> None:
        """Verify ScenarioResultResponse has required fields."""
        opt_id = uuid.uuid4()
        result = ScenarioResultResponse(
            scenario_id=uuid.uuid4(),
            selected_option_id=opt_id,
            is_correct=True,
            explanation="Test explanation",
            recommended_action="Test action",
            answer_options=[
                AnswerOptionWithResult(
                    id=opt_id,
                    text="Correct option",
                    is_correct=True,
                    display_order=0,
                ),
            ],
        )
        dumped = result.model_dump()
        assert dumped["is_correct"] is True
        assert dumped["explanation"] == "Test explanation"

    def test_response_created_shape(self) -> None:
        rid = uuid.uuid4()
        created = ResponseCreated(response_id=rid)
        assert created.response_id == rid


@pytest.mark.asyncio
class TestGetTodayEndpoint:
    async def test_returns_401_without_token(self, client) -> None:
        response = await client.get("/api/v1/scenarios/today")
        assert response.status_code in (401, 422)

    @patch("app.api.v1.endpoints.scenarios.get_today_scenario_for_user")
    async def test_returns_204_when_no_scenario(
        self,
        mock_get_today,
        authed_client,
    ) -> None:
        """With a valid token and no active assignment, returns 204."""
        mock_get_today.return_value = None

        response = await authed_client.get("/api/v1/scenarios/today")
        assert response.status_code == 204

    @patch("app.api.v1.endpoints.scenarios.get_today_scenario_for_user")
    async def test_returns_200_with_scenario(
        self,
        mock_get_today,
        authed_client,
    ) -> None:
        """With a valid token and active assignment, returns 200 without is_correct."""
        scenario = MagicMock()
        scenario.id = uuid.uuid4()
        scenario.title = "Test Scenario"
        scenario.prompt = "Test prompt"
        scenario.category = "phishing"
        scenario.difficulty = "beginner"

        opt = MagicMock()
        opt.id = uuid.uuid4()
        opt.text = "Option 1"
        opt.display_order = 0
        scenario.answer_options = [opt]

        mock_get_today.return_value = scenario

        response = await authed_client.get("/api/v1/scenarios/today")
        assert response.status_code == 200
        data = response.json()
        # T-03: is_correct must never appear
        assert "is_correct" not in str(data)
        assert "title" in data
        assert "answer_options" in data


@pytest.mark.asyncio
class TestGetScenarioEndpoint:
    async def test_returns_401_without_token(self, client) -> None:
        scenario_id = uuid.uuid4()
        response = await client.get(f"/api/v1/scenarios/{scenario_id}")
        assert response.status_code in (401, 422)

    @patch("app.api.v1.endpoints.scenarios.get_scenario_by_id")
    async def test_returns_403_for_unassigned_scenario(
        self,
        mock_get_by_id,
        authed_client,
    ) -> None:
        """T-02: Users cannot access scenarios they are not assigned to."""
        from app.services.scenario_service import NotAssignedError

        mock_get_by_id.side_effect = NotAssignedError

        fake_id = uuid.uuid4()
        response = await authed_client.get(f"/api/v1/scenarios/{fake_id}")
        assert response.status_code == 403


@pytest.mark.asyncio
class TestSubmitResponseEndpoint:
    async def test_returns_401_without_token(self, client) -> None:
        scenario_id = uuid.uuid4()
        response = await client.post(
            f"/api/v1/scenarios/{scenario_id}/responses",
            json={"selected_option_id": str(uuid.uuid4())},
        )
        assert response.status_code in (401, 422)

    @patch("app.api.v1.endpoints.scenarios.submit_response")
    async def test_returns_403_for_unassigned_scenario(
        self,
        mock_submit,
        authed_client,
    ) -> None:
        """T-02: Cannot submit response for unassigned scenario."""
        from app.services.scenario_service import NotAssignedError

        mock_submit.side_effect = NotAssignedError

        fake_id = uuid.uuid4()
        response = await authed_client.post(
            f"/api/v1/scenarios/{fake_id}/responses",
            json={"selected_option_id": str(uuid.uuid4())},
        )
        assert response.status_code == 403


@pytest.mark.asyncio
class TestGetResultEndpoint:
    async def test_returns_401_without_token(self, client) -> None:
        scenario_id = uuid.uuid4()
        response = await client.get(f"/api/v1/scenarios/{scenario_id}/result")
        assert response.status_code in (401, 422)

    @patch("app.api.v1.endpoints.scenarios.get_scenario_result")
    async def test_returns_403_before_submission(
        self,
        mock_get_result,
        authed_client,
    ) -> None:
        """T-03: Results are not available before submission."""
        from app.services.scenario_service import NoResponseExistsError

        mock_get_result.side_effect = NoResponseExistsError

        fake_id = uuid.uuid4()
        response = await authed_client.get(f"/api/v1/scenarios/{fake_id}/result")
        assert response.status_code == 403


@pytest.mark.asyncio
class TestScenarioSecurityInvariants:
    """Cross-cutting security tests for the scenario API."""

    def test_pre_submission_schema_never_leaks_is_correct(self) -> None:
        """T-03: Structural enforcement — pre-submission schemas cannot contain is_correct."""
        # AnswerOptionForEmployee fields
        fields = AnswerOptionForEmployee.model_fields
        assert "is_correct" not in fields, (
            "SECURITY VIOLATION: is_correct found in AnswerOptionForEmployee"
        )

        # ScenarioForEmployee fields (nested)
        scenario_fields = ScenarioForEmployee.model_fields
        assert "is_correct" not in scenario_fields

    def test_post_submission_schema_includes_is_correct(self) -> None:
        """T-03: Post-submission schemas properly include is_correct."""
        fields = AnswerOptionWithResult.model_fields
        assert "is_correct" in fields

        result_fields = ScenarioResultResponse.model_fields
        assert "is_correct" in result_fields
