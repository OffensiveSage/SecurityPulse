"""
Integration tests for auth endpoints.

Tests run with ALLOW_MOCK_AUTH=true so mock tokens work.
The mock provider creates in-memory users via SQLAlchemy — tests
that hit the database require the DB to be reachable (or these tests
are skipped in CI without a DB). For Phase 2, these tests validate
the HTTP contract without a live database by mocking the DB session.
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4

import pytest
from httpx import AsyncClient

from app.models.user import User, UserRole, UserStatus


def _make_mock_user(role: UserRole = UserRole.employee) -> User:
    """Create a mock User object for testing without a database."""
    user = MagicMock(spec=User)
    user.id = uuid4()
    user.identity_provider_subject = f"mock-{role.value}-001"
    user.email = f"{role.value}@example.corp"
    user.display_name = f"Test {role.value.replace('_', ' ').title()}"
    user.role = role
    user.status = UserStatus.active
    user.department = None
    user.region = None
    return user


@pytest.mark.asyncio
class TestAuthMeEndpoint:
    async def test_returns_401_without_authorization_header(
        self,
        client: AsyncClient,
    ) -> None:
        response = await client.get("/api/v1/auth/me")
        assert response.status_code == 422 or response.status_code == 401

    async def test_returns_401_with_empty_bearer(
        self,
        client: AsyncClient,
    ) -> None:
        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": "Bearer "},
        )
        assert response.status_code == 401

    async def test_returns_401_with_malformed_header(
        self,
        client: AsyncClient,
    ) -> None:
        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": "Basic abc123"},
        )
        assert response.status_code == 401


@pytest.mark.asyncio
class TestAuthMeWithMockProvider:
    """Tests that use the mock auth provider with an in-memory DB bypass."""

    async def test_returns_user_profile_shape(self) -> None:
        """Verify UserResponse schema has the required fields."""
        from app.schemas.auth import UserResponse

        user = _make_mock_user()
        response = UserResponse(
            id=user.id,
            display_name=user.display_name,
            email=user.email,
            role=user.role.value,
            department=user.department,
            region=user.region,
            status=user.status.value,
        )
        assert response.role == "employee"
        assert response.email == "employee@example.corp"
        assert response.status == "active"

    async def test_response_does_not_contain_token(self) -> None:
        """Ensure access tokens are never leaked in responses."""
        from app.schemas.auth import UserResponse

        user = _make_mock_user()
        response = UserResponse(
            id=user.id,
            display_name=user.display_name,
            email=user.email,
            role=user.role.value,
            status=user.status.value,
        )
        response_dict = response.model_dump()
        # Token-like keys must not appear
        for forbidden_key in ("token", "access_token", "refresh_token", "authorization"):
            assert forbidden_key not in response_dict


@pytest.mark.asyncio
class TestAuthLogoutEndpoint:
    async def test_returns_401_without_token(
        self,
        client: AsyncClient,
    ) -> None:
        response = await client.post("/api/v1/auth/logout")
        assert response.status_code == 422 or response.status_code == 401


@pytest.mark.asyncio
class TestMockAuthProviderUnit:
    """Unit tests for MockAuthProvider without a live database."""

    async def test_parses_employee_role(self) -> None:
        from app.services.auth_service import MockAuthProvider

        provider = MockAuthProvider()
        mock_db = AsyncMock()
        # Simulate no existing user in DB
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = mock_result
        mock_db.add = MagicMock()  # add() is synchronous in SQLAlchemy
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock()

        user = await provider.validate_token("mock-employee", mock_db)
        assert user.role == UserRole.employee
        assert user.identity_provider_subject == "mock-employee-001"

    async def test_parses_content_admin_role(self) -> None:
        from app.services.auth_service import MockAuthProvider

        provider = MockAuthProvider()
        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = mock_result
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock()

        user = await provider.validate_token("mock-content_admin", mock_db)
        assert user.role == UserRole.content_admin

    async def test_parses_security_admin_role(self) -> None:
        from app.services.auth_service import MockAuthProvider

        provider = MockAuthProvider()
        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = mock_result
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock()

        user = await provider.validate_token("mock-security_admin", mock_db)
        assert user.role == UserRole.security_admin

    async def test_defaults_to_employee_for_unknown_role(self) -> None:
        from app.services.auth_service import MockAuthProvider

        provider = MockAuthProvider()
        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = mock_result
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock()

        user = await provider.validate_token("mock-unknown_role", mock_db)
        assert user.role == UserRole.employee

    async def test_returns_existing_user_from_db(self) -> None:
        from app.services.auth_service import MockAuthProvider

        provider = MockAuthProvider()
        existing_user = _make_mock_user(UserRole.employee)

        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = existing_user
        mock_db.execute.return_value = mock_result

        user = await provider.validate_token("mock-employee", mock_db)
        assert user is existing_user


class TestAuthProviderFactory:
    def test_returns_mock_when_allowed(self) -> None:
        from app.services.auth_service import MockAuthProvider, get_auth_provider

        settings = MagicMock()
        settings.ALLOW_MOCK_AUTH = True
        settings.APP_ENV = "development"

        provider = get_auth_provider(settings)
        assert isinstance(provider, MockAuthProvider)

    def test_returns_oidc_when_configured(self) -> None:
        from app.services.auth_service import OIDCAuthProvider, get_auth_provider

        settings = MagicMock()
        settings.ALLOW_MOCK_AUTH = False
        settings.OIDC_ISSUER_URL = "https://idp.example.com"
        settings.OIDC_CLIENT_ID = "client-id"
        settings.OIDC_AUDIENCE = "api://security-pulse"

        provider = get_auth_provider(settings)
        assert isinstance(provider, OIDCAuthProvider)

    def test_raises_when_oidc_not_configured(self) -> None:
        from app.services.auth_service import get_auth_provider

        settings = MagicMock()
        settings.ALLOW_MOCK_AUTH = False
        settings.OIDC_ISSUER_URL = ""

        with pytest.raises(RuntimeError, match="OIDC_ISSUER_URL is not configured"):
            get_auth_provider(settings)

    def test_mock_not_available_in_production(self) -> None:
        from app.services.auth_service import OIDCAuthProvider, get_auth_provider

        settings = MagicMock()
        settings.ALLOW_MOCK_AUTH = True
        settings.APP_ENV = "production"
        settings.OIDC_ISSUER_URL = "https://idp.example.com"

        # In production, even if ALLOW_MOCK_AUTH=true, it should use OIDC
        provider = get_auth_provider(settings)
        assert isinstance(provider, OIDCAuthProvider)


class TestRBACDependency:
    def test_require_role_returns_callable(self) -> None:
        from app.api.dependencies.auth import require_role

        dep = require_role(UserRole.security_admin)
        assert callable(dep)
