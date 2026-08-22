"""
Integration tests for /me endpoints.

Tests response history and progress endpoints.
Uses dependency overrides for auth and DB so tests run without PostgreSQL.
"""

from __future__ import annotations

from unittest.mock import patch

import pytest


@pytest.mark.asyncio
class TestHistoryEndpoint:
    async def test_returns_401_without_token(self, client) -> None:
        response = await client.get("/api/v1/me/history")
        assert response.status_code in (401, 422)

    @patch("app.api.v1.endpoints.me.get_response_history")
    async def test_returns_paginated_response_with_token(
        self,
        mock_get_history,
        authed_client,
    ) -> None:
        mock_get_history.return_value = ([], 0)

        response = await authed_client.get("/api/v1/me/history")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "meta" in data
        assert isinstance(data["data"], list)
        assert data["meta"]["page"] == 1

    @patch("app.api.v1.endpoints.me.get_response_history")
    async def test_respects_page_and_page_size(
        self,
        mock_get_history,
        authed_client,
    ) -> None:
        mock_get_history.return_value = ([], 0)

        response = await authed_client.get(
            "/api/v1/me/history",
            params={"page": 2, "page_size": 5},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["meta"]["page"] == 2
        assert data["meta"]["page_size"] == 5

    async def test_validates_page_must_be_positive(
        self,
        authed_client,
    ) -> None:
        response = await authed_client.get(
            "/api/v1/me/history",
            params={"page": 0},
        )
        assert response.status_code == 422

    async def test_validates_page_size_max(
        self,
        authed_client,
    ) -> None:
        response = await authed_client.get(
            "/api/v1/me/history",
            params={"page_size": 200},
        )
        assert response.status_code == 422


@pytest.mark.asyncio
class TestProgressEndpoint:
    async def test_returns_401_without_token(self, client) -> None:
        response = await client.get("/api/v1/me/progress")
        assert response.status_code in (401, 422)

    @patch("app.api.v1.endpoints.me.get_user_progress")
    async def test_returns_progress_shape_with_token(
        self,
        mock_get_progress,
        authed_client,
    ) -> None:
        mock_get_progress.return_value = {
            "scenarios_assigned": 5,
            "scenarios_completed": 3,
            "current_streak_days": 2,
        }

        response = await authed_client.get("/api/v1/me/progress")
        assert response.status_code == 200
        data = response.json()
        assert "scenarios_assigned" in data
        assert "scenarios_completed" in data
        assert "current_streak_days" in data
        assert isinstance(data["scenarios_assigned"], int)
        assert isinstance(data["scenarios_completed"], int)
        assert isinstance(data["current_streak_days"], int)

    @patch("app.api.v1.endpoints.me.get_user_progress")
    async def test_zero_state_when_no_data(
        self,
        mock_get_progress,
        authed_client,
    ) -> None:
        """A new user should have zero progress."""
        mock_get_progress.return_value = {
            "scenarios_assigned": 0,
            "scenarios_completed": 0,
            "current_streak_days": 0,
        }

        response = await authed_client.get("/api/v1/me/progress")
        assert response.status_code == 200
        data = response.json()
        assert data["scenarios_completed"] == 0
        assert data["current_streak_days"] == 0
