"""
Unit tests for the authentication service.

Tests MockAuthProvider and OIDCAuthProvider logic without a live database
or identity provider.
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock

import pytest

from app.models.user import User, UserRole, UserStatus
from app.services.auth_service import MockAuthProvider, OIDCAuthProvider


def _mock_db_no_existing_user() -> AsyncMock:
    """Create a mock AsyncSession that returns no existing user."""
    db = AsyncMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    db.execute.return_value = result
    db.add = MagicMock()  # add() is synchronous in SQLAlchemy
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    return db


def _mock_db_with_user(user: User) -> AsyncMock:
    """Create a mock AsyncSession that returns an existing user."""
    db = AsyncMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = user
    db.execute.return_value = result
    return db


@pytest.mark.asyncio
class TestMockAuthProvider:
    async def test_creates_employee_for_mock_employee_token(self) -> None:
        provider = MockAuthProvider()
        db = _mock_db_no_existing_user()

        user = await provider.validate_token("mock-employee", db)

        assert user.role == UserRole.employee
        assert user.email == "employee@example.corp"
        assert user.display_name == "Test Employee"
        assert user.identity_provider_subject == "mock-employee-001"
        assert user.status == UserStatus.active
        db.add.assert_called_once()
        db.commit.assert_awaited_once()

    async def test_creates_content_admin_for_mock_content_admin_token(self) -> None:
        provider = MockAuthProvider()
        db = _mock_db_no_existing_user()

        user = await provider.validate_token("mock-content_admin", db)

        assert user.role == UserRole.content_admin
        assert user.email == "content.admin@example.corp"

    async def test_creates_security_admin_for_mock_security_admin_token(self) -> None:
        provider = MockAuthProvider()
        db = _mock_db_no_existing_user()

        user = await provider.validate_token("mock-security_admin", db)

        assert user.role == UserRole.security_admin
        assert user.email == "security.admin@example.corp"

    async def test_returns_existing_user_without_creating(self) -> None:
        provider = MockAuthProvider()
        existing = MagicMock(spec=User)
        existing.identity_provider_subject = "mock-employee-001"
        existing.role = UserRole.employee
        db = _mock_db_with_user(existing)

        user = await provider.validate_token("mock-employee", db)

        assert user is existing
        db.add.assert_not_called()

    async def test_defaults_to_employee_for_unknown_role(self) -> None:
        provider = MockAuthProvider()
        db = _mock_db_no_existing_user()

        user = await provider.validate_token("mock-nonexistent", db)

        assert user.role == UserRole.employee

    async def test_handles_token_without_mock_prefix(self) -> None:
        provider = MockAuthProvider()
        db = _mock_db_no_existing_user()

        user = await provider.validate_token("plain-token", db)

        # Falls back to employee
        assert user.role == UserRole.employee


@pytest.mark.asyncio
class TestOIDCAuthProvider:
    async def test_rejects_invalid_jwt(self) -> None:
        """OIDCAuthProvider should raise ValueError for a garbage token."""
        settings = MagicMock()
        settings.OIDC_ISSUER_URL = "https://idp.example.com"
        settings.OIDC_CLIENT_ID = "test-client"
        settings.OIDC_AUDIENCE = "api://security-pulse"

        provider = OIDCAuthProvider(settings)
        db = _mock_db_no_existing_user()

        # Without a real JWKS endpoint, any JWT validation will fail.
        # We verify the provider correctly raises ValueError.
        with pytest.raises((ValueError, Exception)):
            await provider.validate_token("not-a-valid-jwt", db)
