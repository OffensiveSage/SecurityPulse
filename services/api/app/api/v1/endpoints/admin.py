"""Admin endpoints: analytics, campaigns, audit events."""

from __future__ import annotations

import math
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies.auth import get_current_user, require_role
from app.core.database import get_db_session
from app.models.audit_event import AuditEvent
from app.models.user import User, UserRole
from app.schemas.admin import (
    AnalyticsSummary,
    AuditEventSchema,
    CampaignCreate,
    CampaignSchema,
    EligibilityResult,
)
from app.schemas.common import PaginatedResponse, PaginationMeta
from app.services import analytics_service, campaign_service
from app.services.audit_service import persist_audit_event

router = APIRouter(prefix="/admin")


@router.get(
    "/analytics/summary",
    response_model=AnalyticsSummary,
    dependencies=[
        Depends(
            require_role(UserRole.approver, UserRole.platform_admin, UserRole.security_admin)
        )
    ],
)
async def analytics_summary(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
    x_correlation_id: Annotated[str | None, Header()] = None,
) -> AnalyticsSummary:
    """Aggregated analytics summary. Individual data is never returned."""
    await persist_audit_event(
        action="analytics.export_downloaded",
        actor_id=current_user.id,
        target_type="analytics",
        correlation_id=x_correlation_id,
        db=db,
    )
    return await analytics_service.get_analytics_summary(db)


@router.get(
    "/campaigns",
    response_model=PaginatedResponse[CampaignSchema],
    dependencies=[
        Depends(
            require_role(UserRole.approver, UserRole.platform_admin, UserRole.security_admin)
        )
    ],
)
async def list_campaigns(
    db: Annotated[AsyncSession, Depends(get_db_session)],
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
) -> PaginatedResponse[CampaignSchema]:
    """Return a paginated list of campaigns."""
    return await campaign_service.list_campaigns(db, page=page, page_size=page_size)


@router.post(
    "/campaigns",
    response_model=CampaignSchema,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_role(UserRole.approver, UserRole.platform_admin))],
)
async def create_campaign(
    payload: CampaignCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
    x_correlation_id: Annotated[str | None, Header()] = None,
) -> CampaignSchema:
    """Create a new campaign in draft status."""
    result = await campaign_service.create_campaign(payload, db)
    await persist_audit_event(
        action="campaign.created",
        actor_id=current_user.id,
        target_type="campaign",
        target_id=str(result.id),
        after_summary=f"name={result.name}",
        correlation_id=x_correlation_id,
        db=db,
    )
    return result


@router.post(
    "/campaigns/{campaign_id}/calculate-eligibility",
    response_model=EligibilityResult,
    dependencies=[
        Depends(
            require_role(UserRole.approver, UserRole.platform_admin, UserRole.security_admin)
        )
    ],
)
async def calculate_eligibility(
    campaign_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
    x_correlation_id: Annotated[str | None, Header()] = None,
) -> EligibilityResult:
    """Calculate the number of eligible users for a campaign."""
    try:
        result = await campaign_service.calculate_eligibility(campaign_id, db)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)
        ) from exc

    await persist_audit_event(
        action="campaign.eligibility_calculated",
        actor_id=current_user.id,
        target_type="campaign",
        target_id=str(campaign_id),
        after_summary=f"eligible_count={result.eligible_count}",
        correlation_id=x_correlation_id,
        db=db,
    )
    return result


@router.get(
    "/audit-events",
    response_model=PaginatedResponse[AuditEventSchema],
    dependencies=[Depends(require_role(UserRole.platform_admin, UserRole.security_admin))],
)
async def list_audit_events(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
    action: Annotated[str | None, Query()] = None,
    x_correlation_id: Annotated[str | None, Header()] = None,
) -> PaginatedResponse[AuditEventSchema]:
    """List audit events with optional action filter. Access itself is audit-logged."""
    # Audit the audit access itself
    await persist_audit_event(
        action="audit_events.accessed",
        actor_id=current_user.id,
        target_type="audit_events",
        correlation_id=x_correlation_id,
        db=db,
    )

    stmt = select(AuditEvent).order_by(AuditEvent.timestamp.desc())
    if action is not None:
        stmt = stmt.where(AuditEvent.action.contains(action))

    count_base = select(AuditEvent)
    if action is not None:
        count_base = count_base.where(AuditEvent.action.contains(action))
    count_q = select(func.count()).select_from(count_base.subquery())
    total = (await db.execute(count_q)).scalar_one()

    offset = (page - 1) * page_size
    rows = (await db.execute(stmt.offset(offset).limit(page_size))).scalars().all()

    return PaginatedResponse[AuditEventSchema](
        data=[AuditEventSchema.model_validate(r) for r in rows],
        meta=PaginationMeta(
            page=page,
            page_size=page_size,
            total=total,
            total_pages=max(1, math.ceil(total / page_size)),
        ),
    )
