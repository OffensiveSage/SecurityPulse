"""
Auth-related Pydantic schemas.

These models define request/response shapes for auth endpoints
and internal token payload structures.
"""

from __future__ import annotations

import uuid

from pydantic import BaseModel


class TokenPayload(BaseModel):
    """Decoded JWT token claims (internal use only, never logged)."""

    sub: str
    email: str | None = None
    name: str | None = None
    exp: int
    iss: str
    aud: str | list[str]


class UserResponse(BaseModel):
    """Response schema for GET /api/v1/auth/me."""

    id: uuid.UUID
    display_name: str | None = None
    email: str | None = None
    role: str
    department: str | None = None
    region: str | None = None
    status: str

    model_config = {"from_attributes": True}
