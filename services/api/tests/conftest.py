"""
Pytest configuration and shared fixtures.

Mock auth fixtures are available in development/test mode only.
Tests override get_current_user and get_db_session to avoid
requiring a live PostgreSQL database.
"""

from __future__ import annotations

import os
import uuid
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.models.user import User, UserRole, UserStatus

# Enable mock auth for tests before any app import
os.environ.setdefault("ALLOW_MOCK_AUTH", "true")
os.environ.setdefault("APP_ENV", "development")

from app.api.dependencies.auth import get_current_user  # noqa: E402
from app.core.database import get_db_session  # noqa: E402
from app.main import create_application  # noqa: E402


def _make_mock_user(role: UserRole = UserRole.employee) -> User:
    """Create a mock User object for testing without a database."""
    user = MagicMock(spec=User)
    user.id = uuid.UUID("00000000-0000-0000-0000-000000000001")
    user.identity_provider_subject = f"mock-{role.value}-001"
    user.email = f"{role.value}@example.corp"
    user.display_name = f"Test {role.value.replace('_', ' ').title()}"
    user.role = role
    user.status = UserStatus.active
    user.department = None
    user.region = None
    return user


def _make_mock_db() -> AsyncMock:
    """Create a mock AsyncSession for testing without a database."""
    db = AsyncMock()
    db.add = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    db.rollback = AsyncMock()
    return db


@pytest.fixture
def mock_user() -> User:
    """A mock employee user for dependency overrides."""
    return _make_mock_user()


@pytest.fixture
def mock_db() -> AsyncMock:
    """A mock DB session for dependency overrides."""
    return _make_mock_db()


@pytest.fixture
def app():
    """Create a test application instance."""
    return create_application()


@pytest.fixture
async def client(app):
    """Async HTTP client for integration tests (no dependency overrides)."""
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac


@pytest.fixture
async def authed_client(app, mock_user, mock_db):
    """Async HTTP client with auth and DB dependencies overridden.

    Use this for endpoint tests that need authentication but
    don't require a live database.
    """
    app.dependency_overrides[get_current_user] = lambda: mock_user
    app.dependency_overrides[get_db_session] = lambda: mock_db

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac

    app.dependency_overrides.clear()


@pytest.fixture
def mock_employee_headers() -> dict[str, str]:
    """Authorization headers for a mock employee user."""
    return {"Authorization": "Bearer mock-employee"}


@pytest.fixture
def mock_content_admin_headers() -> dict[str, str]:
    """Authorization headers for a mock content_admin user."""
    return {"Authorization": "Bearer mock-content_admin"}


@pytest.fixture
def mock_security_admin_headers() -> dict[str, str]:
    """Authorization headers for a mock security_admin user."""
    return {"Authorization": "Bearer mock-security_admin"}
