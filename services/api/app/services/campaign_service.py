"""Campaign service: list, create, eligibility calculation."""

from __future__ import annotations

import math
import uuid
from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.campaign import Campaign, CampaignStatus
from app.models.response import Response
from app.schemas.admin import (
    MIN_ANALYTICS_GROUP_SIZE,
    CampaignCreate,
    CampaignSchema,
    EligibilityResult,
)
from app.schemas.common import PaginatedResponse, PaginationMeta

GOVERNANCE_DISCLAIMER = (
    "Final winner selection and prize fulfillment require approval from HR, Legal, Tax, "
    "and Ethics. This eligibility count is for planning purposes only."
)


async def list_campaigns(
    db: AsyncSession,
    page: int = 1,
    page_size: int = 20,
) -> PaginatedResponse[CampaignSchema]:
    """Return a paginated list of campaigns ordered by creation date descending."""
    count_stmt = select(func.count()).select_from(Campaign)
    total = (await db.execute(count_stmt)).scalar_one()

    offset = (page - 1) * page_size
    stmt = (
        select(Campaign).order_by(Campaign.created_at.desc()).offset(offset).limit(page_size)
    )
    rows = (await db.execute(stmt)).scalars().all()

    data = [
        CampaignSchema(
            id=c.id,
            name=c.name,
            status=c.status.value,
            start_at=c.start_at,
            end_at=c.end_at,
            eligibility_rule=c.eligibility_rule,
            reward_description=c.reward_description,
            governance_disclaimer=GOVERNANCE_DISCLAIMER,
        )
        for c in rows
    ]

    return PaginatedResponse[CampaignSchema](
        data=data,
        meta=PaginationMeta(
            page=page,
            page_size=page_size,
            total=total,
            total_pages=max(1, math.ceil(total / page_size)),
        ),
    )


async def create_campaign(payload: CampaignCreate, db: AsyncSession) -> CampaignSchema:
    """Persist a new campaign in draft status and return its schema."""
    campaign = Campaign(
        name=payload.name,
        start_at=payload.start_at,
        end_at=payload.end_at,
        eligibility_rule=payload.eligibility_rule,
        reward_description=payload.reward_description,
        status=CampaignStatus.draft,
    )
    db.add(campaign)
    await db.commit()
    await db.refresh(campaign)

    return CampaignSchema(
        id=campaign.id,
        name=campaign.name,
        status=campaign.status.value,
        start_at=campaign.start_at,
        end_at=campaign.end_at,
        eligibility_rule=campaign.eligibility_rule,
        reward_description=campaign.reward_description,
        governance_disclaimer=GOVERNANCE_DISCLAIMER,
    )


async def calculate_eligibility(
    campaign_id: uuid.UUID, db: AsyncSession
) -> EligibilityResult:
    """Count users who submitted at least one response during the campaign window.

    Suppresses count if below MIN_ANALYTICS_GROUP_SIZE to prevent
    individual identification.

    Raises:
        ValueError: If the campaign does not exist.
    """
    campaign = await db.get(Campaign, campaign_id)
    if campaign is None:
        raise ValueError(f"Campaign {campaign_id} not found")

    stmt = (
        select(func.count(func.distinct(Response.user_id)))
        .select_from(Response)
        .where(
            Response.submitted_at >= campaign.start_at,
            Response.submitted_at <= campaign.end_at,
        )
    )
    count = (await db.execute(stmt)).scalar_one()
    suppressed = count < MIN_ANALYTICS_GROUP_SIZE

    return EligibilityResult(
        eligible_count=count if not suppressed else 0,
        calculated_at=datetime.now(UTC),
        suppressed=suppressed,
    )
