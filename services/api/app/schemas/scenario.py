"""
Scenario-related Pydantic schemas.

Security note (T-03): Pre-submission schemas (AnswerOptionForEmployee,
ScenarioForEmployee) deliberately exclude is_correct. Post-submission
schemas (AnswerOptionWithResult, ScenarioResultResponse) include it.
This structural separation makes accidental leakage impossible.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field

# --- Pre-submission schemas (T-03: no is_correct) ---


class AnswerOptionForEmployee(BaseModel):
    """Answer option as shown to employees before submission. No is_correct field."""

    id: uuid.UUID
    text: str
    display_order: int

    model_config = {"from_attributes": True}


class ScenarioForEmployee(BaseModel):
    """Scenario as shown to employees before submission."""

    id: uuid.UUID
    title: str
    prompt: str
    category: str
    difficulty: str
    answer_options: list[AnswerOptionForEmployee]

    model_config = {"from_attributes": True}


# --- Post-submission schemas (T-03: includes is_correct after response exists) ---


class AnswerOptionWithResult(BaseModel):
    """Answer option with correctness revealed after submission."""

    id: uuid.UUID
    text: str
    is_correct: bool
    display_order: int

    model_config = {"from_attributes": True}


class ScenarioResultResponse(BaseModel):
    """Result returned after a user has submitted a response."""

    scenario_id: uuid.UUID
    selected_option_id: uuid.UUID
    is_correct: bool
    explanation: str
    recommended_action: str
    answer_options: list[AnswerOptionWithResult]


# --- Request schemas ---


class ResponseSubmission(BaseModel):
    """Request body for POST /scenarios/{scenario_id}/responses."""

    selected_option_id: uuid.UUID
    response_time_ms: int | None = Field(default=None, ge=0)
    source: str | None = Field(default=None, pattern=r"^(app|widget)$")


# --- Response schemas ---


class ResponseCreated(BaseModel):
    """Response body for POST /scenarios/{scenario_id}/responses."""

    response_id: uuid.UUID


class ResponseRecord(BaseModel):
    """A single entry in the user's response history."""

    id: uuid.UUID
    scenario_id: uuid.UUID
    scenario_title: str
    submitted_at: datetime
    is_correct: bool

    model_config = {"from_attributes": True}


class UserProgress(BaseModel):
    """Summary of a user's progress."""

    scenarios_assigned: int
    scenarios_completed: int
    current_streak_days: int
    campaign_eligible: bool | None = None
