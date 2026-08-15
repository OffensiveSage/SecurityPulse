"""Create scenario, campaign, assignment, response, and audit_event tables.

Revision ID: 0002
Revises: 0001
Create Date: 2026-08-13
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # --- campaigns ---
    op.create_table(
        "campaigns",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("start_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("end_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "eligibility_rule",
            sa.Text(),
            nullable=True,
            comment="JSON rule for audience eligibility.",
        ),
        sa.Column(
            "status",
            sa.Enum(
                "draft",
                "active",
                "completed",
                "cancelled",
                name="campaign_status",
                native_enum=False,
            ),
            nullable=False,
            server_default="draft",
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

    # --- scenarios ---
    op.create_table(
        "scenarios",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("prompt", sa.Text(), nullable=False),
        sa.Column(
            "category",
            sa.Enum(
                "phishing",
                "password_security",
                "social_engineering",
                "data_protection",
                "device_security",
                "physical_security",
                name="scenario_category",
                native_enum=False,
            ),
            nullable=False,
        ),
        sa.Column(
            "difficulty",
            sa.Enum(
                "beginner",
                "intermediate",
                "advanced",
                name="scenario_difficulty",
                native_enum=False,
            ),
            nullable=False,
            server_default="beginner",
        ),
        sa.Column("explanation", sa.Text(), nullable=False),
        sa.Column("recommended_action", sa.Text(), nullable=False),
        sa.Column(
            "status",
            sa.Enum(
                "draft",
                "review",
                "approved",
                "published",
                "retired",
                name="scenario_status",
                native_enum=False,
            ),
            nullable=False,
            server_default="draft",
        ),
        sa.Column("publish_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expire_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("version", sa.Integer(), nullable=False, server_default="1"),
        sa.Column(
            "created_by",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id"),
            nullable=True,
        ),
        sa.Column(
            "approved_by",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id"),
            nullable=True,
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
    op.create_index("ix_scenarios_status", "scenarios", ["status"])

    # --- answer_options ---
    op.create_table(
        "answer_options",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "scenario_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("scenarios.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("text", sa.Text(), nullable=False),
        sa.Column("is_correct", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("display_order", sa.Integer(), nullable=False, server_default="0"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_answer_options_scenario_id", "answer_options", ["scenario_id"])

    # --- assignments ---
    op.create_table(
        "assignments",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "scenario_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("scenarios.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=True,
        ),
        sa.Column(
            "audience_rule",
            sa.Text(),
            nullable=True,
            comment="JSON rule for audience targeting when user_id is null.",
        ),
        sa.Column("available_from", sa.DateTime(timezone=True), nullable=False),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "campaign_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("campaigns.id", ondelete="SET NULL"),
            nullable=True,
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
    op.create_index("ix_assignments_user_id", "assignments", ["user_id"])
    op.create_index("ix_assignments_scenario_id", "assignments", ["scenario_id"])
    op.create_index(
        "ix_assignments_available_from_due_at",
        "assignments",
        ["available_from", "due_at"],
    )

    # --- responses ---
    op.create_table(
        "responses",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "scenario_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("scenarios.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "selected_option_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("answer_options.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("is_correct", sa.Boolean(), nullable=False),
        sa.Column(
            "response_time_ms",
            sa.Integer(),
            nullable=True,
            comment="Time in milliseconds the user spent answering.",
        ),
        sa.Column(
            "source",
            sa.Enum("app", "widget", name="response_source", native_enum=False),
            nullable=False,
            server_default="app",
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
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "scenario_id", name="uq_responses_user_scenario"),
    )
    op.create_index("ix_responses_user_id", "responses", ["user_id"])
    op.create_index("ix_responses_scenario_id", "responses", ["scenario_id"])

    # --- audit_events ---
    op.create_table(
        "audit_events",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "actor_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
            comment="The user who performed the action. Null for system events.",
        ),
        sa.Column("action", sa.String(100), nullable=False),
        sa.Column(
            "target_type",
            sa.String(100),
            nullable=True,
            comment="The type of object the action was performed on.",
        ),
        sa.Column(
            "target_id",
            sa.String(255),
            nullable=True,
            comment="The ID of the object the action was performed on.",
        ),
        sa.Column(
            "before_summary",
            sa.Text(),
            nullable=True,
            comment="Summary of state before the action.",
        ),
        sa.Column(
            "after_summary",
            sa.Text(),
            nullable=True,
            comment="Summary of state after the action.",
        ),
        sa.Column(
            "timestamp",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "correlation_id",
            sa.String(255),
            nullable=True,
            comment="Request correlation ID for tracing.",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_audit_events_action", "audit_events", ["action"])
    op.create_index("ix_audit_events_timestamp", "audit_events", ["timestamp"])


def downgrade() -> None:
    op.drop_index("ix_audit_events_timestamp", table_name="audit_events")
    op.drop_index("ix_audit_events_action", table_name="audit_events")
    op.drop_table("audit_events")

    op.drop_index("ix_responses_scenario_id", table_name="responses")
    op.drop_index("ix_responses_user_id", table_name="responses")
    op.drop_table("responses")

    op.drop_index("ix_assignments_available_from_due_at", table_name="assignments")
    op.drop_index("ix_assignments_scenario_id", table_name="assignments")
    op.drop_index("ix_assignments_user_id", table_name="assignments")
    op.drop_table("assignments")

    op.drop_index("ix_answer_options_scenario_id", table_name="answer_options")
    op.drop_table("answer_options")

    op.drop_index("ix_scenarios_status", table_name="scenarios")
    op.drop_table("scenarios")

    op.drop_table("campaigns")
