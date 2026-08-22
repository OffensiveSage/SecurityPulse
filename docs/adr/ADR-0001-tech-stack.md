# ADR-0001: Technology Stack

**Status:** Accepted  
**Date:** 2026-08-03  
**Deciders:** Architecture team

---

## Context

Security Pulse requires a mobile app for iOS, iPadOS, and Android, a web-based admin portal, a REST API backend, and home-screen widgets on both platforms.

## Decision

We adopt the following stack as specified in `PRODUCT_SPEC.md § 4`:

| Component | Technology | Version target |
|---|---|---|
| Mobile app | Flutter + Dart | 3.24.x stable |
| iOS widget | SwiftUI + WidgetKit | iOS 16+ |
| Android widget | Kotlin + Jetpack Glance | Android 12+ |
| Admin portal | Next.js + TypeScript | 14.x |
| Backend API | Python + FastAPI | 0.115.x |
| ORM | SQLAlchemy 2.x + Alembic | Latest stable |
| Database | PostgreSQL | 16 |
| Cache | Redis | 7 |
| State management | Riverpod 2 + riverpod_generator | 2.5.x |
| Navigation | GoRouter | 14.x |
| HTTP client | Dio + Retrofit | 5.x |
| Auth (mobile) | flutter_appauth | 7.x |
| Token storage | flutter_secure_storage | 9.x |
| DI | get_it + injectable | 8.x / 2.x |
| Auth (admin) | OIDC server-side (library TBD) | — |

## Consequences

- Flutter enables a single Dart codebase for iOS and Android, reducing maintenance cost.
- Native widgets are required because Flutter cannot directly implement WidgetKit or Jetpack Glance extensions.
- The widget bridge requires a clearly defined non-sensitive `DailyCardModel` data contract.
- FastAPI provides good async performance and automatic OpenAPI documentation generation.
- The OpenAPI spec in `packages/api-contract/openapi.yaml` is the source of truth for the API contract; it must be committed and versioned.

## Alternatives considered

- React Native: rejected due to weaker support for native widget extensions and platform channels.
- Django REST Framework: rejected due to heavier synchronous model for a primarily async workload.
- Express.js: rejected to maintain a consistent Python ecosystem for backend and worker.
