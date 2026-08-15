"""
Campaign ORM model.

A campaign groups scenario assignments over a time period.
"""

from __future__ import annotations

import enum

from sqlalchemy import DateTime, Enum, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class CampaignStatus(enum.StrEnum):
    """Lifecycle states for a campaign."""

    draft = "draft"
    active = "active"
    completed = "completed"
    cancelled = "cancelled"


class Campaign(Base, UUIDMixin, TimestampMixin):
    """A campaign that groups scenario assignments over a time window."""

    __tablename__ = "campaigns"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    start_at: Mapped[DateTime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    end_at: Mapped[DateTime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    eligibility_rule: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
        comment="JSON rule for audience eligibility.",
    )

    status: Mapped[CampaignStatus] = mapped_column(
        Enum(CampaignStatus, name="campaign_status", native_enum=False),
        nullable=False,
        default=CampaignStatus.draft,
        server_default="draft",
    )

    def __repr__(self) -> str:
        return f"<Campaign id={self.id} name={self.name!r} status={self.status.value}>"
