"""
Security Pulse — FastAPI application entry point.

This module creates and configures the FastAPI application instance.
All routers, middleware, and lifecycle hooks are registered here.
"""

from __future__ import annotations

import sys
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.cli.seed import seed_dev_data
from app.core.config import get_settings
from app.core.database import engine
from app.core.logging import configure_logging

logger = structlog.get_logger(__name__)


def _assert_production_safety() -> None:
    """
    Refuse to start if production safety invariants are violated.

    This check runs at startup to catch dangerous misconfigurations
    before the application accepts traffic.
    """
    settings = get_settings()
    if settings.APP_ENV == "production" and settings.ALLOW_MOCK_AUTH:
        print(  # noqa: T201
            "FATAL: ALLOW_MOCK_AUTH=true is not permitted when APP_ENV=production. "
            "Set ALLOW_MOCK_AUTH=false or fix APP_ENV.",
            file=sys.stderr,
        )
        sys.exit(1)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan: startup and shutdown hooks."""
    _assert_production_safety()
    settings = get_settings()
    logger.info(
        "security_pulse_api_starting",
        env=settings.APP_ENV,
        mock_auth=settings.ALLOW_MOCK_AUTH,
        version=settings.APP_VERSION,
    )
    # Seed development data if in dev mode with mock auth
    if settings.ALLOW_MOCK_AUTH and settings.APP_ENV == "development":
        await seed_dev_data(engine)

    yield
    logger.info("security_pulse_api_stopping")


def create_application() -> FastAPI:
    """Create and configure the FastAPI application."""
    settings = get_settings()
    configure_logging(settings.LOG_LEVEL, settings.LOG_FORMAT)

    app = FastAPI(
        title="Security Pulse API",
        description="Corporate cybersecurity awareness platform API",
        version=settings.APP_VERSION,
        docs_url="/docs" if settings.APP_ENV == "development" else None,
        redoc_url="/redoc" if settings.APP_ENV == "development" else None,
        openapi_url="/openapi.json" if settings.APP_ENV == "development" else None,
        lifespan=lifespan,
    )

    # CORS — restrict to approved origins
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.API_CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "X-Correlation-Id", "Idempotency-Key"],
    )

    # Register API routes
    app.include_router(api_router)

    return app


app = create_application()
