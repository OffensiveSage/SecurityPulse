"""
Scenario and AnswerOption ORM models.

A scenario represents a daily security awareness question.
Each scenario has multiple answer options, exactly one of which is correct.
"""

from __future__ import annotations

import enum
import uuid

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDMixin


class ScenarioStatus(enum.StrEnum):
    """Content lifecycle states for a scenario."""

    draft = "draft"
    review = "review"
    approved = "approved"
    published = "published"
    retired = "retired"


class ScenarioDifficulty(enum.StrEnum):
    """Difficulty level for a scenario."""

    beginner = "beginner"
    intermediate = "intermediate"
    advanced = "advanced"


class ScenarioCategory(enum.StrEnum):
    """Topic category for a scenario."""

    phishing = "phishing"
    password_security = "password_security"  # noqa: S105
    social_engineering = "social_engineering"
    data_protection = "data_protection"
    device_security = "device_security"
    physical_security = "physical_security"


class Scenario(Base, UUIDMixin, TimestampMixin):
    """A security awareness scenario presented as a daily question."""

    __tablename__ = "scenarios"

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    prompt: Mapped[str] = mapped_column(Text, nullable=False)

    category: Mapped[ScenarioCategory] = mapped_column(
        Enum(ScenarioCategory, name="scenario_category", native_enum=False),
        nullable=False,
    )

    difficulty: Mapped[ScenarioDifficulty] = mapped_column(
        Enum(ScenarioDifficulty, name="scenario_difficulty", native_enum=False),
        nullable=False,
        default=ScenarioDifficulty.beginner,
        server_default="beginner",
    )

    explanation: Mapped[str] = mapped_column(Text, nullable=False)
    recommended_action: Mapped[str] = mapped_column(Text, nullable=False)

    status: Mapped[ScenarioStatus] = mapped_column(
        Enum(ScenarioStatus, name="scenario_status", native_enum=False),
        nullable=False,
        default=ScenarioStatus.draft,
        server_default="draft",
    )

    publish_at: Mapped[DateTime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    expire_at: Mapped[DateTime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    version: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=1,
        server_default="1",
    )

    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        nullable=True,
    )
    approved_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        nullable=True,
    )

    # Relationships
    answer_options: Mapped[list[AnswerOption]] = relationship(
        "AnswerOption",
        back_populates="scenario",
        order_by="AnswerOption.display_order",
        lazy="selectin",
    )

    def __repr__(self) -> str:
        return f"<Scenario id={self.id} title={self.title!r} status={self.status.value}>"


class AnswerOption(Base, UUIDMixin):
    """An answer option for a scenario question."""

    __tablename__ = "answer_options"

    scenario_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("scenarios.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    text: Mapped[str] = mapped_column(Text, nullable=False)
    is_correct: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    display_order: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )

    # Relationships
    scenario: Mapped[Scenario] = relationship(
        "Scenario",
        back_populates="answer_options",
    )

    def __repr__(self) -> str:
        return f"<AnswerOption id={self.id} correct={self.is_correct}>"
