"""
Health check endpoints.

These endpoints are unauthenticated and used by:
- Docker Compose healthcheck
- Container orchestration liveness/readiness probes
- Monitoring systems

GET /health       — liveness: service is running
GET /health/ready — readiness: service can accept traffic (DB + Redis reachable)
"""

from __future__ import annotations

import structlog
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import text

from app.core.config import get_settings
from app.core.database import AsyncSessionLocal

logger = structlog.get_logger(__name__)
router = APIRouter()


class HealthResponse(BaseModel):
    """Health check response."""

    status: str
    version: str
    env: str


class ReadinessResponse(BaseModel):
    """Readiness check response including dependency status."""

    status: str
    version: str
    env: str
    checks: dict[str, str]


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Liveness check",
    description="Returns 200 if the service process is running.",
)
async def health_liveness() -> HealthResponse:
    """Liveness probe — confirms the process is alive."""
    settings = get_settings()
    return HealthResponse(
        status="ok",
        version=settings.APP_VERSION,
        env=settings.APP_ENV,
    )


@router.get(
    "/health/ready",
    response_model=ReadinessResponse,
    summary="Readiness check",
    description="Returns 200 if the service can accept traffic. Checks database and Redis.",
)
async def health_readiness() -> ReadinessResponse:
    """
    Readiness probe — confirms all dependencies are reachable.

    Returns 503 if any critical dependency is unavailable.
    """
    settings = get_settings()
    checks: dict[str, str] = {}
    is_ready = True

    # Check PostgreSQL
    try:
        async with AsyncSessionLocal() as session:
            await session.execute(text("SELECT 1"))
        checks["database"] = "ok"
    except Exception as exc:
        logger.warning("health_readiness_database_failed", error=str(exc))
        checks["database"] = "error"
        is_ready = False

    # Check Redis
    try:
        import redis.asyncio as aioredis

        r = aioredis.from_url(settings.REDIS_URL, socket_connect_timeout=2)
        await r.ping()
        await r.aclose()
        checks["redis"] = "ok"
    except Exception as exc:
        logger.warning("health_readiness_redis_failed", error=str(exc))
        checks["redis"] = "error"
        is_ready = False

    response = ReadinessResponse(
        status="ready" if is_ready else "unavailable",
        version=settings.APP_VERSION,
        env=settings.APP_ENV,
        checks=checks,
    )

    if not is_ready:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=response.model_dump(),
        )

    return response
