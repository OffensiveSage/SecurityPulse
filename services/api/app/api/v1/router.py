"""
API v1 router.

Aggregates all v1 endpoint routers under /api/v1.
"""

from __future__ import annotations

from fastapi import APIRouter

from app.api.v1.endpoints import health

# Root router — includes health (unauthenticated) and versioned API
api_router = APIRouter()

# Health endpoints — no authentication required
api_router.include_router(health.router, tags=["health"])

# Versioned API prefix
v1_router = APIRouter(prefix="/api/v1")

# TODO (Phase 2): Add auth endpoints
# TODO (Phase 3): Add scenario endpoints
# TODO (Phase 4): Add widget endpoint
# TODO (Phase 5): Add incident report endpoints
# TODO (Phase 6): Add admin endpoints

api_router.include_router(v1_router)
