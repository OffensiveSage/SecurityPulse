"""
Assignment ORM model.

An assignment links a scenario to a user (or audience rule) for a time window.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.scenario import Scenario


class Assignment(Base, UUIDMixin, TimestampMixin):
    """Links a scenario to a user for a specific availability window."""

    __tablename__ = "assignments"

    scenario_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("scenarios.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    audience_rule: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
        comment="JSON rule for audience targeting when user_id is null.",
    )

    available_from: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    due_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    campaign_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("campaigns.id", ondelete="SET NULL"),
        nullable=True,
    )

    # Relationships
    scenario: Mapped[Scenario] = relationship(  # noqa: F821
        "Scenario",
        lazy="selectin",
    )

    def __repr__(self) -> str:
        return f"<Assignment id={self.id} scenario={self.scenario_id} user={self.user_id}>"
