"""
Pytest configuration and shared fixtures.

Mock auth fixtures are available in development/test mode only.
"""

from __future__ import annotations

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import create_application


@pytest.fixture
def app():
    """Create a test application instance."""
    return create_application()


@pytest.fixture
async def client(app):
    """Async HTTP client for integration tests."""
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac
