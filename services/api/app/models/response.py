"""
Response ORM model.

A response records a user's answer to a scenario question.
Unique constraint on (user_id, scenario_id) prevents duplicate submissions (T-04).
"""

from __future__ import annotations

import enum
import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, UUIDMixin

if TYPE_CHECKING:
    from app.models.scenario import Scenario


class ResponseSource(enum.StrEnum):
    """Where the response was submitted from."""

    app = "app"
    widget = "widget"


class Response(Base, UUIDMixin):
    """A user's answer to a scenario question."""

    __tablename__ = "responses"
    __table_args__ = (
        UniqueConstraint("user_id", "scenario_id", name="uq_responses_user_scenario"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    scenario_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("scenarios.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    selected_option_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("answer_options.id", ondelete="CASCADE"),
        nullable=False,
    )

    is_correct: Mapped[bool] = mapped_column(Boolean, nullable=False)

    response_time_ms: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
        comment="Time in milliseconds the user spent answering.",
    )

    source: Mapped[ResponseSource] = mapped_column(
        Enum(ResponseSource, name="response_source", native_enum=False),
        nullable=False,
        default=ResponseSource.app,
        server_default="app",
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

    # Relationships
    scenario: Mapped[Scenario] = relationship(  # noqa: F821
        "Scenario",
        lazy="selectin",
    )

    def __repr__(self) -> str:
        return (
            f"<Response id={self.id} user={self.user_id} "
            f"scenario={self.scenario_id} correct={self.is_correct}>"
        )
