"""
Structured audit logging for security-relevant events.

Records auth events (sign-in, sign-out, failures) using structlog.
Also provides persist_audit_event for writing AuditEvent rows to the database.
Never logs: access tokens, refresh tokens, passwords, MFA codes.
"""

from __future__ import annotations

import uuid

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.audit_event import AuditEvent

logger = structlog.get_logger("audit")


async def log_auth_event(
    *,
    action: str,
    actor_subject: str | None = None,
    correlation_id: str | None = None,
    details: dict[str, str] | None = None,
) -> None:
    """Log an authentication event.

    Args:
        action: Event type (e.g. 'sign_in', 'sign_in_failed', 'sign_out').
        actor_subject: The IdP 'sub' claim identifying the actor. Never a token.
        correlation_id: Request correlation ID for tracing.
        details: Additional context (e.g. failure reason). Never include secrets.
    """
    logger.info(
        "auth_event",
        action=action,
        actor_subject=actor_subject,
        correlation_id=correlation_id,
        **(details or {}),
    )


async def persist_audit_event(
    *,
    action: str,
    actor_id: uuid.UUID | None = None,
    target_type: str | None = None,
    target_id: str | None = None,
    before_summary: str | None = None,
    after_summary: str | None = None,
    correlation_id: str | None = None,
    db: AsyncSession,
) -> None:
    """Write an AuditEvent row to the database.

    Args:
        action: Machine-readable event type (e.g. 'campaign.created').
        actor_id: UUID of the user who performed the action.
        target_type: The type of object affected (e.g. 'campaign').
        target_id: String ID of the affected object.
        before_summary: Summary of state before the action.
        after_summary: Summary of state after the action.
        correlation_id: Request correlation ID for distributed tracing.
        db: Async database session.
    """
    event = AuditEvent(
        actor_id=actor_id,
        action=action,
        target_type=target_type,
        target_id=target_id,
        before_summary=before_summary,
        after_summary=after_summary,
        correlation_id=correlation_id,
    )
    db.add(event)
    await db.commit()
