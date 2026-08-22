"""
AuditEvent ORM model.

Records security-relevant actions for the audit trail.
Uses explicit timestamp field instead of TimestampMixin.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin


class AuditEvent(Base, UUIDMixin):
    """An immutable audit trail entry for security-relevant actions."""

    __tablename__ = "audit_events"

    actor_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        comment="The user who performed the action. Null for system events.",
    )

    action: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        index=True,
    )

    target_type: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
        comment="The type of object the action was performed on (e.g. 'scenario', 'response').",
    )

    target_id: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
        comment="The ID of the object the action was performed on.",
    )

    before_summary: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
        comment="Summary of state before the action (for update/delete).",
    )

    after_summary: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
        comment="Summary of state after the action (for create/update).",
    )

    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )

    correlation_id: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
        comment="Request correlation ID for tracing.",
    )

    def __repr__(self) -> str:
        return f"<AuditEvent id={self.id} action={self.action!r} actor={self.actor_id}>"
