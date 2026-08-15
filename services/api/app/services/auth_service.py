"""
Authentication service with strategy pattern.

Two providers:
- OIDCAuthProvider: validates real OIDC JWT tokens from a corporate IdP.
- MockAuthProvider: development-only mock that accepts an X-Mock-User-Role header.

The active provider is selected at startup via get_auth_provider().
"""

from __future__ import annotations

import uuid
from typing import Protocol

import httpx
import structlog
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.models.user import User, UserRole, UserStatus

logger = structlog.get_logger(__name__)

# JWKS cache (module-level, refreshed by OIDCAuthProvider)
_jwks_cache: dict[str, object] | None = None
_jwks_cache_url: str | None = None


class AuthProvider(Protocol):
    """Protocol for authentication providers."""

    async def validate_token(
        self,
        token: str,
        db: AsyncSession,
    ) -> User:
        """Validate a token and return the authenticated User.

        Raises ValueError if the token is invalid.
        Never logs the token value.
        """
        ...


class OIDCAuthProvider:
    """Validates real OIDC JWT tokens using JWKS from the identity provider."""

    def __init__(self, settings: Settings) -> None:
        self._issuer_url = settings.OIDC_ISSUER_URL
        self._client_id = settings.OIDC_CLIENT_ID
        self._audience = settings.OIDC_AUDIENCE
        self._jwks_uri: str | None = None

    async def _get_jwks(self) -> dict[str, object]:
        """Fetch and cache the JWKS from the IdP's discovery endpoint."""
        global _jwks_cache, _jwks_cache_url  # noqa: PLW0603

        discovery_url = f"{self._issuer_url.rstrip('/')}/.well-known/openid-configuration"

        if _jwks_cache is not None and _jwks_cache_url == discovery_url:
            return _jwks_cache

        async with httpx.AsyncClient() as client:
            discovery_resp = await client.get(discovery_url, timeout=10.0)
            discovery_resp.raise_for_status()
            jwks_uri = discovery_resp.json()["jwks_uri"]

            jwks_resp = await client.get(jwks_uri, timeout=10.0)
            jwks_resp.raise_for_status()
            _jwks_cache = jwks_resp.json()
            _jwks_cache_url = discovery_url

        return _jwks_cache

    async def validate_token(
        self,
        token: str,
        db: AsyncSession,
    ) -> User:
        """Validate a JWT and return the corresponding User (JIT-provisioned)."""
        try:
            jwks = await self._get_jwks()
            payload = jwt.decode(
                token,
                jwks,
                algorithms=["RS256"],
                audience=self._audience,
                issuer=self._issuer_url,
            )
        except JWTError as exc:
            logger.warning("oidc_token_validation_failed", error=str(exc))
            msg = "Invalid or expired token"
            raise ValueError(msg) from exc

        sub: str = payload["sub"]
        email: str | None = payload.get("email")
        name: str | None = payload.get("name")

        # Look up existing user or JIT-provision
        result = await db.execute(
            select(User).where(User.identity_provider_subject == sub),
        )
        user = result.scalar_one_or_none()

        if user is None:
            user = User(
                id=uuid.uuid4(),
                identity_provider_subject=sub,
                email=email,
                display_name=name,
                role=UserRole.employee,
                status=UserStatus.active,
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)
            logger.info("user_jit_provisioned", user_id=str(user.id), sub=sub)
        else:
            # Update display attributes if changed at the IdP
            changed = False
            if email and user.email != email:
                user.email = email
                changed = True
            if name and user.display_name != name:
                user.display_name = name
                changed = True
            if changed:
                await db.commit()
                await db.refresh(user)

        return user


class MockAuthProvider:
    """Development-only mock authentication.

    Accepts a Bearer token in the format 'mock-<role>' (e.g. 'mock-employee')
    or reads X-Mock-User-Role header value.

    This provider is only available when ALLOW_MOCK_AUTH=true and
    APP_ENV != 'production'. The production safety check in main.py
    prevents this from ever running in production.
    """

    _mock_users: dict[str, dict[str, str]] = {
        "employee": {
            "sub": "mock-employee-001",
            "email": "employee@example.corp",
            "name": "Test Employee",
        },
        "content_admin": {
            "sub": "mock-content-admin-001",
            "email": "content.admin@example.corp",
            "name": "Test Content Admin",
        },
        "security_admin": {
            "sub": "mock-security-admin-001",
            "email": "security.admin@example.corp",
            "name": "Test Security Admin",
        },
    }

    async def validate_token(
        self,
        token: str,
        db: AsyncSession,
    ) -> User:
        """Parse mock token and return a test user."""
        # Token format: 'mock-<role>' e.g. 'mock-employee'
        role_str = token.removeprefix("mock-") if token.startswith("mock-") else "employee"

        try:
            role = UserRole(role_str)
        except ValueError:
            role = UserRole.employee

        mock_data = self._mock_users.get(role.value, self._mock_users["employee"])
        sub = mock_data["sub"]

        # Look up or create mock user in DB
        result = await db.execute(
            select(User).where(User.identity_provider_subject == sub),
        )
        user = result.scalar_one_or_none()

        if user is None:
            user = User(
                id=uuid.uuid4(),
                identity_provider_subject=sub,
                email=mock_data["email"],
                display_name=mock_data["name"],
                role=role,
                status=UserStatus.active,
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)

        return user


def get_auth_provider(settings: Settings) -> AuthProvider:
    """Factory: select the appropriate auth provider based on settings."""
    if settings.ALLOW_MOCK_AUTH and settings.APP_ENV != "production":
        logger.info("auth_provider_selected", provider="mock")
        return MockAuthProvider()

    if not settings.OIDC_ISSUER_URL:
        msg = (
            "OIDC_ISSUER_URL is not configured. "
            "Set OIDC_ISSUER_URL or enable ALLOW_MOCK_AUTH for development."
        )
        raise RuntimeError(msg)

    logger.info("auth_provider_selected", provider="oidc")
    return OIDCAuthProvider(settings)
