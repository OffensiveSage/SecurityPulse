"""
Incident report Pydantic schemas.

Security notes:
- T-11: Credential patterns (passwords, MFA codes) are rejected in descriptions.
- Metadata fields are validated against report_type to prevent arbitrary data.
"""

from __future__ import annotations

import re
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

from pydantic import BaseModel, Field, field_validator, model_validator

from app.models.incident_report import IncidentSeverity, ReportType

# Patterns that suggest credential data (T-11).
_CREDENTIAL_PATTERNS = re.compile(
    r"(?i)"
    r"(?:password\s*[:=]\s*\S+)"
    r"|(?:mfa[\s_-]*code\s*[:=]\s*\S+)"
    r"|(?:auth[\s_-]*token\s*[:=]\s*\S+)"
    r"|(?:api[\s_-]*key\s*[:=]\s*\S+)"
    r"|(?:secret[\s_-]*key\s*[:=]\s*\S+)"
)

# Keys forbidden in metadata_fields.
_FORBIDDEN_METADATA_KEYS = frozenset(
    {
        "password",
        "auth_token",
        "mfa_code",
        "api_key",
        "secret_key",
        "access_token",
        "refresh_token",
    }
)

# Valid metadata keys per report type.
_VALID_METADATA_KEYS: dict[ReportType, frozenset[str]] = {
    ReportType.suspicious_email: frozenset({"sender_or_url"}),
    ReportType.suspicious_link: frozenset({"sender_or_url"}),
    ReportType.unauthorized_access: frozenset({"system_affected"}),
    ReportType.lost_device: frozenset({"device_type", "last_known_location"}),
    ReportType.data_exposure: frozenset({"data_classification"}),
}


# --- Request schemas ---


class IncidentReportCreate(BaseModel):
    """Request body for POST /api/v1/incidents."""

    report_type: ReportType
    title: str = Field(min_length=5, max_length=100)
    description: str = Field(min_length=10, max_length=2000)
    occurred_at: datetime
    severity: IncidentSeverity | None = None
    metadata_fields: dict[str, Any] | None = Field(default=None)

    @field_validator("occurred_at")
    @classmethod
    def occurred_at_not_future(cls, v: datetime) -> datetime:
        # 5-minute tolerance for clock skew.
        if v > datetime.now(UTC) + timedelta(minutes=5):
            msg = "occurred_at cannot be in the future"
            raise ValueError(msg)
        return v

    @field_validator("description")
    @classmethod
    def reject_credential_patterns(cls, v: str) -> str:
        if _CREDENTIAL_PATTERNS.search(v):
            msg = (
                "Description appears to contain credentials. "
                "Never include passwords, MFA codes, or API keys."
            )
            raise ValueError(msg)
        return v

    @field_validator("metadata_fields")
    @classmethod
    def validate_metadata_no_tokens(
        cls,
        v: dict[str, Any] | None,
    ) -> dict[str, Any] | None:
        if v is None:
            return v
        forbidden = _FORBIDDEN_METADATA_KEYS & set(v.keys())
        if forbidden:
            msg = f"Forbidden metadata keys: {', '.join(sorted(forbidden))}"
            raise ValueError(msg)
        return v

    @model_validator(mode="after")
    def validate_metadata_keys_for_type(self) -> IncidentReportCreate:
        if self.metadata_fields is None:
            return self
        allowed = _VALID_METADATA_KEYS.get(self.report_type, frozenset())
        unknown = set(self.metadata_fields.keys()) - allowed
        if unknown:
            msg = (
                f"Unexpected metadata keys for {self.report_type.value}: "
                f"{', '.join(sorted(unknown))}"
            )
            raise ValueError(msg)
        return self


# --- Response schemas ---


class IncidentReportCreated(BaseModel):
    """Response body for POST /api/v1/incidents (201)."""

    report_id: uuid.UUID


class IncidentReportSummary(BaseModel):
    """List item in report history."""

    id: uuid.UUID
    report_type: str
    title: str
    severity: str | None
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class IncidentReportResponse(BaseModel):
    """Full incident report detail."""

    id: uuid.UUID
    report_type: str
    title: str
    description: str
    occurred_at: datetime
    severity: str | None
    metadata_fields: dict[str, Any] | None
    status: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
