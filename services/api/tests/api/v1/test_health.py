"""
Tests for health check endpoints.

These endpoints are unauthenticated; they must always return quickly.
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
class TestLiveness:
    async def test_returns_200(self, client: AsyncClient) -> None:
        response = await client.get("/health")
        assert response.status_code == 200

    async def test_response_structure(self, client: AsyncClient) -> None:
        response = await client.get("/health")
        body = response.json()
        assert body["status"] == "ok"
        assert "version" in body
        assert "env" in body

    async def test_env_is_development_in_test(self, client: AsyncClient) -> None:
        response = await client.get("/health")
        body = response.json()
        # Tests run in development mode
        assert body["env"] == "development"


@pytest.mark.asyncio
class TestReadiness:
    async def test_endpoint_exists(self, client: AsyncClient) -> None:
        """Readiness endpoint must exist even if dependencies are unavailable."""
        response = await client.get("/health/ready")
        # Either 200 (all deps up) or 503 (deps unavailable in test environment)
        assert response.status_code in (200, 503)

    async def test_response_has_checks(self, client: AsyncClient) -> None:
        response = await client.get("/health/ready")
        body = response.json()
        # 200 path
        if response.status_code == 200:
            assert "checks" in body
            assert "database" in body["checks"]
            assert "redis" in body["checks"]
        # 503 path — FastAPI wraps in detail
        else:
            detail = body.get("detail", {})
            assert "checks" in detail
