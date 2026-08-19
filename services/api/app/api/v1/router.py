"""
API v1 router.

Aggregates all v1 endpoint routers under /api/v1.
"""

from __future__ import annotations

from fastapi import APIRouter

from app.api.v1.endpoints import admin, auth, health, incidents, me, scenarios

# Root router — includes health (unauthenticated) and versioned API
api_router = APIRouter()

# Health endpoints — no authentication required
api_router.include_router(health.router, tags=["health"])

# Versioned API prefix
v1_router = APIRouter(prefix="/api/v1")

# Auth endpoints
v1_router.include_router(auth.router, tags=["auth"])

# Scenario endpoints (Phase 3)
v1_router.include_router(scenarios.router, tags=["scenarios"])
v1_router.include_router(me.router, tags=["me"])

# Incident report endpoints (Phase 4)
v1_router.include_router(incidents.router, tags=["incidents"])

# Admin endpoints (Phase 6)
v1_router.include_router(admin.router, tags=["admin"])

api_router.include_router(v1_router)
