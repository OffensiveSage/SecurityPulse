"""
Incident routing abstraction.

After an incident report is persisted, the router forwards it to external
systems (email, webhook, ticketing). The default LogOnlyIncidentRouter
simply logs the report for development and testing.

Future implementations:
- EmailIncidentRouter: Sends email to SOC team.
- WebhookIncidentRouter: POSTs to a configured webhook URL.
- ServiceNowIncidentRouter: Creates a ServiceNow ticket.
- JiraIncidentRouter: Creates a Jira issue.
"""

from __future__ import annotations

import abc
from typing import TYPE_CHECKING

import structlog

if TYPE_CHECKING:
    from app.models.incident_report import IncidentReport

logger = structlog.get_logger(__name__)


class IncidentRouterBase(abc.ABC):
    """Abstract interface for routing incident reports to external systems."""

    @abc.abstractmethod
    async def route(self, report: IncidentReport) -> None:
        """Route a persisted incident report.

        Called fire-and-forget after DB commit. Implementations must not
        raise exceptions that would block the API response.
        """


class LogOnlyIncidentRouter(IncidentRouterBase):
    """Default no-op router that logs the report for development/testing."""

    async def route(self, report: IncidentReport) -> None:
        logger.info(
            "incident_routed",
            report_id=str(report.id),
            report_type=report.report_type.value,
            severity=report.severity.value if report.severity else None,
        )


def get_incident_router() -> IncidentRouterBase:
    """Factory function. Returns LogOnlyIncidentRouter by default."""
    return LogOnlyIncidentRouter()
