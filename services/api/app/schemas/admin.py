"""Admin Pydantic schemas: analytics, campaigns, audit events."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field

MIN_ANALYTICS_GROUP_SIZE = 5


class CategoryAccuracy(BaseModel):
    category: str
    response_count: int
    accuracy_rate: float = Field(ge=0, le=1)
    suppressed: bool = False


class AnalyticsSummary(BaseModel):
    total_employees_active: int
    total_responses: int
    overall_accuracy_rate: float = Field(ge=0, le=1)
    participation_rate: float = Field(ge=0, le=1)
    by_category: list[CategoryAccuracy] | None = None
    suppression_applied: bool = False


class CampaignSchema(BaseModel):
    id: uuid.UUID
    name: str
    status: str
    start_at: datetime | None
    end_at: datetime | None
    eligibility_rule: str | None
    reward_description: str | None
    governance_disclaimer: str

    model_config = {"from_attributes": True}


class CampaignCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    start_at: datetime
    end_at: datetime
    eligibility_rule: str = Field(min_length=1)
    reward_description: str | None = None


class EligibilityResult(BaseModel):
    eligible_count: int
    calculated_at: datetime
    suppressed: bool = False


class AuditEventSchema(BaseModel):
    id: uuid.UUID
    actor_id: uuid.UUID | None
    action: str
    target_type: str | None
    target_id: str | None
    before_summary: str | None
    after_summary: str | None
    timestamp: datetime
    correlation_id: str | None

    model_config = {"from_attributes": True}
