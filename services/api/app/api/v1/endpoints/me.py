"""
User self-service endpoints.

GET /api/v1/me/history  — Paginated response history.
GET /api/v1/me/progress — User progress summary.
"""

from __future__ import annotations

import math
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies.auth import get_current_user
from app.core.database import get_db_session
from app.models.user import User
from app.schemas.common import PaginatedResponse, PaginationMeta
from app.schemas.scenario import ResponseRecord, UserProgress
from app.services.scenario_service import get_response_history, get_user_progress

router = APIRouter(prefix="/me")


@router.get("/history", response_model=PaginatedResponse[ResponseRecord])
async def history(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
) -> PaginatedResponse[ResponseRecord]:
    """Get the authenticated user's response history, most recent first."""
    records, total = await get_response_history(
        current_user.id,
        db,
        page=page,
        page_size=page_size,
    )

    return PaginatedResponse[ResponseRecord](
        data=[ResponseRecord(**r) for r in records],
        meta=PaginationMeta(
            page=page,
            page_size=page_size,
            total=total,
            total_pages=max(1, math.ceil(total / page_size)),
        ),
    )


@router.get("/progress", response_model=UserProgress)
async def progress(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
) -> UserProgress:
    """Get the authenticated user's progress summary."""
    result = await get_user_progress(current_user.id, db)
    return UserProgress(**result)
