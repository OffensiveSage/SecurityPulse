"""Phase 6: add admin roles, reward_description to campaigns, campaign_eligible support.

Revision ID: 0004
Revises: 0003
Create Date: 2026-08-19
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0004"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Ensure any rows with legacy or unknown role values are normalised to 'employee'
    # before the application starts validating the enum. Stored as VARCHAR so no
    # ALTER TYPE is needed.
    op.execute(
        "UPDATE users SET role = 'employee' WHERE role NOT IN "
        "('employee','content_admin','security_admin','author','reviewer',"
        "'approver','soc_analyst','platform_admin')"
    )

    # Add reward_description column to campaigns
    op.add_column("campaigns", sa.Column("reward_description", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("campaigns", "reward_description")
