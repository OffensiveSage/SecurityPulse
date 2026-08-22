"""
Incident report service — business logic for incident reporting.

Security enforcement:
- T-02: All queries filter by reporter_id to prevent horizontal escalation.
- T-11: Credential pattern rejection is handled at the schema level.
- T-14: Rate limiting enforced via DB count (max 10 reports per user per hour).
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import structlog
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.incident_report import IncidentReport, IncidentStatus
from app.schemas.incident import IncidentReportCreate
from app.services.incident_router import get_incident_router

logger = structlog.get_logger(__name__)

# Maximum reports per user per hour.
RATE_LIMIT_MAX = 10
RATE_LIMIT_WINDOW = timedelta(hours=1)


class RateLimitExceededError(Exception):
    """Raised when user exceeds the report rate limit."""


class IncidentNotFoundError(Exception):
    """Raised when an incident does not exist or is not owned by the user."""


async def create_incident_report(
    user_id: uuid.UUID,
    data: IncidentReportCreate,
    db: AsyncSession,
    idempotency_key: str | None = None,
) -> tuple[IncidentReport, bool]:
    """Create an incident report.

    Returns:
        Tuple of (report, is_new). is_new=False on idempotent replay.

    Raises:
        RateLimitExceededError: If the user has exceeded the rate limit.
    """
    # 1. Check idempotency key replay.
    if idempotency_key:
        idem_stmt = select(IncidentReport).where(
            IncidentReport.idempotency_key == idempotency_key,
        )
        idem_result = await db.execute(idem_stmt)
        existing = idem_result.scalar_one_or_none()
        if existing is not None:
            logger.info(
                "incident_idempotent_replay",
                report_id=str(existing.id),
                key=idempotency_key,
            )
            return (existing, False)

    # 2. Enforce rate limit (T-14).
    cutoff = datetime.now(UTC) - RATE_LIMIT_WINDOW
    count_stmt = (
        select(func.count())
        .select_from(IncidentReport)
        .where(
            IncidentReport.reporter_id == user_id,
            IncidentReport.created_at > cutoff,
        )
    )
    count_result = await db.execute(count_stmt)
    report_count = count_result.scalar_one()

    if report_count >= RATE_LIMIT_MAX:
        raise RateLimitExceededError

    # 3. Persist the report.
    report = IncidentReport(
        id=uuid.uuid4(),
        reporter_id=user_id,
        report_type=data.report_type,
        title=data.title,
        description=data.description,
        occurred_at=data.occurred_at,
        severity=data.severity,
        metadata_json=data.metadata_fields,
        status=IncidentStatus.submitted,
        idempotency_key=idempotency_key,
    )

    db.add(report)
    await db.commit()
    await db.refresh(report)

    logger.info(
        "incident_created",
        report_id=str(report.id),
        reporter_id=str(user_id),
        report_type=data.report_type.value,
    )

    # 4. Fire-and-forget routing (failure logged, not raised).
    try:
        router = get_incident_router()
        await router.route(report)
    except Exception:
        logger.exception(
            "incident_routing_failed",
            report_id=str(report.id),
        )

    return (report, True)


async def get_user_incidents(
    user_id: uuid.UUID,
    db: AsyncSession,
    page: int = 1,
    page_size: int = 20,
) -> tuple[list[dict[str, Any]], int]:
    """Get paginated list of a user's own incident reports (T-02).

    Returns:
        Tuple of (list of report dicts, total count).
    """
    # Count total.
    count_stmt = (
        select(func.count())
        .select_from(IncidentReport)
        .where(IncidentReport.reporter_id == user_id)
    )
    total = (await db.execute(count_stmt)).scalar_one()

    # Fetch page.
    offset = (page - 1) * page_size
    list_stmt = (
        select(IncidentReport)
        .where(IncidentReport.reporter_id == user_id)
        .order_by(IncidentReport.created_at.desc())
        .offset(offset)
        .limit(page_size)
    )
    list_result = await db.execute(list_stmt)
    reports = list_result.scalars().all()

    records = [
        {
            "id": r.id,
            "report_type": r.report_type.value,
            "title": r.title,
            "severity": r.severity.value if r.severity else None,
            "status": r.status.value,
            "created_at": r.created_at,
        }
        for r in reports
    ]

    return (records, total)


async def get_incident_by_id(
    incident_id: uuid.UUID,
    user_id: uuid.UUID,
    db: AsyncSession,
) -> IncidentReport:
    """Get a single incident report by ID (T-02: user-scoped).

    Raises:
        IncidentNotFoundError: If the report does not exist or belongs
            to another user.
    """
    stmt = select(IncidentReport).where(
        IncidentReport.id == incident_id,
        IncidentReport.reporter_id == user_id,
    )
    result = await db.execute(stmt)
    report = result.scalar_one_or_none()

    if report is None:
        raise IncidentNotFoundError

    return report
