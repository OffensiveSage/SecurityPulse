"""
Authentication and authorization dependencies for FastAPI.

get_current_user: Extracts and validates Bearer token, returns User.
require_role: Returns a dependency that enforces RBAC by role.

Security rules:
- Deny by default: every protected endpoint returns 401/403 unless explicitly allowed.
- Never log token values.
- Server validates every token on every request (no client trust).
"""

from __future__ import annotations

from collections.abc import Callable, Coroutine
from typing import Annotated, Any

import structlog
from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings, get_settings
from app.core.database import get_db_session
from app.models.user import User, UserRole
from app.services.auth_service import get_auth_provider

logger = structlog.get_logger(__name__)


async def get_current_user(
    authorization: Annotated[str, Header()],
    db: Annotated[AsyncSession, Depends(get_db_session)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> User:
    """Extract Bearer token from Authorization header and return the authenticated User.

    Raises:
        HTTPException 401: If token is missing, malformed, or invalid.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or malformed Authorization header. Expected: Bearer <token>",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Empty bearer token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    provider = get_auth_provider(settings)

    try:
        user = await provider.validate_token(token, db)
    except (ValueError, RuntimeError) as exc:
        logger.warning("auth_failed", error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    if user.status.value != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive.",
        )

    return user


def require_role(
    *allowed_roles: UserRole,
) -> Callable[..., Coroutine[Any, Any, User]]:
    """Return a FastAPI dependency that enforces RBAC.

    Usage:
        @router.get("/admin/...", dependencies=[Depends(require_role(UserRole.security_admin))])

    Raises:
        HTTPException 403: If user's role is not in allowed_roles.
    """

    async def _check_role(
        current_user: Annotated[User, Depends(get_current_user)],
    ) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions.",
            )
        return current_user

    return _check_role
