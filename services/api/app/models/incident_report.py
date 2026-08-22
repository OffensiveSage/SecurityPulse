"""
Incident report ORM model.

An incident report records a user's report of suspicious security activity.
Only the reporter can view their own reports (T-02).
Rate limiting enforced at the service layer (T-14).
"""

from __future__ import annotations

import enum
import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class ReportType(enum.StrEnum):
    """Category of incident being reported."""

    suspicious_email = "suspicious_email"
    suspicious_link = "suspicious_link"
    unauthorized_access = "unauthorized_access"
    data_exposure = "data_exposure"
    lost_device = "lost_device"
    social_engineering = "social_engineering"
    malware_warning = "malware_warning"
    physical_security = "physical_security"
    other = "other"


class IncidentSeverity(enum.StrEnum):
    """Self-assessed severity of the incident."""

    low = "low"
    medium = "medium"
    high = "high"
    critical = "critical"


class IncidentStatus(enum.StrEnum):
    """Lifecycle status of an incident report."""

    submitted = "submitted"
    acknowledged = "acknowledged"
    investigating = "investigating"
    resolved = "resolved"
    closed = "closed"


class IncidentReport(Base, UUIDMixin, TimestampMixin):
    """An employee's report of a suspicious security incident."""

    __tablename__ = "incident_reports"

    reporter_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    report_type: Mapped[ReportType] = mapped_column(
        Enum(ReportType, name="report_type", native_enum=False),
        nullable=False,
    )

    title: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    description: Mapped[str] = mapped_column(
        Text(),
        nullable=False,
    )

    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    severity: Mapped[IncidentSeverity | None] = mapped_column(
        Enum(IncidentSeverity, name="incident_severity", native_enum=False),
        nullable=True,
    )

    # Named metadata_json to avoid conflict with SQLAlchemy's reserved `metadata`.
    metadata_json: Mapped[dict[str, Any] | None] = mapped_column(
        JSONB,
        nullable=True,
        comment="Type-specific conditional fields (e.g. sender_or_url, device_type).",
    )

    status: Mapped[IncidentStatus] = mapped_column(
        Enum(IncidentStatus, name="incident_status", native_enum=False),
        nullable=False,
        default=IncidentStatus.submitted,
        server_default="submitted",
    )

    idempotency_key: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
        unique=True,
        comment="Client-provided key to ensure idempotent submission.",
    )

    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    def __repr__(self) -> str:
        return f"<IncidentReport id={self.id} type={self.report_type} status={self.status}>"
