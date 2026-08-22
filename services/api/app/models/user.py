"""
User ORM model.

Represents an employee or administrator in the Security Pulse platform.
"""

from __future__ import annotations

import enum

from sqlalchemy import Enum, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class UserRole(enum.StrEnum):
    """All roles supported by the platform (Phase 2 + Phase 6 additions)."""

    employee = "employee"
    author = "author"
    reviewer = "reviewer"
    approver = "approver"
    soc_analyst = "soc_analyst"
    platform_admin = "platform_admin"
    # Keep for backward compatibility (pre-Phase 6)
    content_admin = "content_admin"
    security_admin = "security_admin"


class UserStatus(enum.StrEnum):
    """Account status."""

    active = "active"
    inactive = "inactive"


class User(Base, UUIDMixin, TimestampMixin):
    """A platform user provisioned from the corporate identity provider."""

    __tablename__ = "users"

    identity_provider_subject: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        index=True,
        nullable=False,
        comment="The 'sub' claim from the OIDC identity provider.",
    )

    email: Mapped[str | None] = mapped_column(
        String(320),
        nullable=True,
    )

    display_name: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    department: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    region: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role", native_enum=False),
        nullable=False,
        default=UserRole.employee,
        server_default="employee",
    )

    status: Mapped[UserStatus] = mapped_column(
        Enum(UserStatus, name="user_status", native_enum=False),
        nullable=False,
        default=UserStatus.active,
        server_default="active",
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} sub={self.identity_provider_subject} role={self.role.value}>"
