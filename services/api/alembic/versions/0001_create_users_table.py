"""Create users table.

Revision ID: 0001
Revises:
Create Date: 2026-08-13
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "identity_provider_subject",
            sa.String(255),
            nullable=False,
            comment="The 'sub' claim from the OIDC identity provider.",
        ),
        sa.Column("email", sa.String(320), nullable=True),
        sa.Column("display_name", sa.String(255), nullable=True),
        sa.Column("department", sa.String(255), nullable=True),
        sa.Column("region", sa.String(100), nullable=True),
        sa.Column(
            "role",
            sa.Enum(
                "employee",
                "content_admin",
                "security_admin",
                name="user_role",
                native_enum=False,
            ),
            nullable=False,
            server_default="employee",
        ),
        sa.Column(
            "status",
            sa.Enum("active", "inactive", name="user_status", native_enum=False),
            nullable=False,
            server_default="active",
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
        "ix_users_identity_provider_subject",
        "users",
        ["identity_provider_subject"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index("ix_users_identity_provider_subject", table_name="users")
    op.drop_table("users")
