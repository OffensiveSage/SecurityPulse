"""Create incident_reports table.

Revision ID: 0003
Revises: 0002
Create Date: 2026-08-15
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0003"
down_revision: str | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "incident_reports",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "reporter_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "report_type",
            sa.Enum(
                "suspicious_email",
                "suspicious_link",
                "unauthorized_access",
                "data_exposure",
                "lost_device",
                "social_engineering",
                "malware_warning",
                "physical_security",
                "other",
                name="report_type",
                native_enum=False,
            ),
            nullable=False,
        ),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column(
            "occurred_at",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.Column(
            "severity",
            sa.Enum(
                "low",
                "medium",
                "high",
                "critical",
                name="incident_severity",
                native_enum=False,
            ),
            nullable=True,
        ),
        sa.Column(
            "metadata_json",
            postgresql.JSONB,
            nullable=True,
            comment="Type-specific conditional fields.",
        ),
        sa.Column(
            "status",
            sa.Enum(
                "submitted",
                "acknowledged",
                "investigating",
                "resolved",
                "closed",
                name="incident_status",
                native_enum=False,
            ),
            nullable=False,
            server_default="submitted",
        ),
        sa.Column(
            "idempotency_key",
            sa.String(255),
            nullable=True,
            unique=True,
            comment="Client-provided key to ensure idempotent submission.",
        ),
        sa.Column(
            "submitted_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_incident_reports_reporter_id",
        "incident_reports",
        ["reporter_id"],
    )
    op.create_index(
        "ix_incident_reports_report_type",
        "incident_reports",
        ["report_type"],
    )
    op.create_index(
        "ix_incident_reports_status",
        "incident_reports",
        ["status"],
    )
    op.create_index(
        "ix_incident_reports_created_at",
        "incident_reports",
        ["created_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_incident_reports_created_at", table_name="incident_reports")
    op.drop_index("ix_incident_reports_status", table_name="incident_reports")
    op.drop_index("ix_incident_reports_report_type", table_name="incident_reports")
    op.drop_index("ix_incident_reports_reporter_id", table_name="incident_reports")
    op.drop_table("incident_reports")
