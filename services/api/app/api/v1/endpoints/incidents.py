"""
Incident report endpoints.

POST /api/v1/incidents            — Create an incident report.
GET  /api/v1/incidents/mine       — Paginated list of user's own reports.
GET  /api/v1/incidents/{id}       — Single report detail.

Security:
- T-02: All endpoints scope queries to the authenticated user.
- T-14: Rate limiting enforced at the service layer.
"""

from __future__ import annotations

import math
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies.auth import get_current_user
from app.core.database import get_db_session
from app.models.user import User
from app.schemas.common import PaginatedResponse, PaginationMeta
from app.schemas.incident import (
    IncidentReportCreate,
    IncidentReportCreated,
    IncidentReportResponse,
    IncidentReportSummary,
)
from app.services.incident_service import (
    IncidentNotFoundError,
    RateLimitExceededError,
    create_incident_report,
    get_incident_by_id,
    get_user_incidents,
)

router = APIRouter(prefix="/incidents")


@router.post(
    "",
    response_model=IncidentReportCreated,
    status_code=status.HTTP_201_CREATED,
)
async def create_incident(
    body: IncidentReportCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
    idempotency_key: Annotated[
        str | None,
        Header(alias="Idempotency-Key"),
    ] = None,
) -> Response | IncidentReportCreated:
    """Create an incident report.

    Returns 201 on first submission, 200 on idempotent replay.
    Returns 429 when rate limit is exceeded.
    """
    try:
        report, is_new = await create_incident_report(
            user_id=current_user.id,
            data=body,
            db=db,
            idempotency_key=idempotency_key,
        )
    except RateLimitExceededError:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Rate limit exceeded. Maximum 10 reports per hour.",
        ) from None

    created = IncidentReportCreated(report_id=report.id)
    if not is_new:
        return Response(
            content=created.model_dump_json(),
            status_code=status.HTTP_200_OK,
            media_type="application/json",
        )

    return created


@router.get("/mine", response_model=PaginatedResponse[IncidentReportSummary])
async def list_my_incidents(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
) -> PaginatedResponse[IncidentReportSummary]:
    """Get the authenticated user's incident reports, most recent first."""
    records, total = await get_user_incidents(
        current_user.id,
        db,
        page=page,
        page_size=page_size,
    )

    return PaginatedResponse[IncidentReportSummary](
        data=[IncidentReportSummary(**r) for r in records],
        meta=PaginationMeta(
            page=page,
            page_size=page_size,
            total=total,
            total_pages=max(1, math.ceil(total / page_size)),
        ),
    )


@router.get("/{incident_id}", response_model=IncidentReportResponse)
async def get_incident(
    incident_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
) -> IncidentReportResponse:
    """Get a single incident report by ID (T-02: user-scoped)."""
    try:
        report = await get_incident_by_id(
            incident_id,
            current_user.id,
            db,
        )
    except IncidentNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Incident report not found.",
        ) from None

    return IncidentReportResponse(
        id=report.id,
        report_type=report.report_type.value,
        title=report.title,
        description=report.description,
        occurred_at=report.occurred_at,
        severity=report.severity.value if report.severity else None,
        metadata_fields=report.metadata_json,
        status=report.status.value,
        created_at=report.created_at,
        updated_at=report.updated_at,
    )
