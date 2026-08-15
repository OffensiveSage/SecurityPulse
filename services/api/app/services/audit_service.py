"""
Structured audit logging for security-relevant events.

Records auth events (sign-in, sign-out, failures) using structlog.
Never logs: access tokens, refresh tokens, passwords, MFA codes.
"""

from __future__ import annotations

import structlog

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
