"""
Authentication endpoints.

GET  /api/v1/auth/me     — Returns the authenticated user's profile.
POST /api/v1/auth/logout  — Signals sign-out (client clears tokens).
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Response, status

from app.api.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.auth import UserResponse
from app.services.audit_service import log_auth_event

router = APIRouter(prefix="/auth")


@router.get("/me", response_model=UserResponse)
async def auth_me(
    current_user: Annotated[User, Depends(get_current_user)],
) -> UserResponse:
    """Return the authenticated user's identity and role."""
    return UserResponse(
        id=current_user.id,
        display_name=current_user.display_name,
        email=current_user.email,
        role=current_user.role.value,
        department=current_user.department,
        region=current_user.region,
        status=current_user.status.value,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def auth_logout(
    current_user: Annotated[User, Depends(get_current_user)],
) -> Response:
    """Sign out the current user.

    In Phase 2 with stateless JWTs, the server-side is a no-op.
    The client is responsible for clearing stored tokens.
    Future enhancement: add token to a Redis denylist.
    """
    await log_auth_event(
        action="sign_out",
        actor_subject=current_user.identity_provider_subject,
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
