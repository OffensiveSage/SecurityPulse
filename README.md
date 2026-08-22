# Security Pulse

Corporate cybersecurity awareness platform for iOS, iPadOS, and Android.

**Document version:** 1.0  
**Stack:** Flutter · FastAPI · Next.js · PostgreSQL · Redis

---

## What this is

Security Pulse delivers short, role-based security scenarios that employees complete in under one minute. A home-screen widget shows the daily question. The mobile app handles answers, explanations, streaks, incident reporting, and notifications. An administrative web portal manages content, campaigns, and analytics.

This is an awareness and reporting companion—not a replacement for annual compliance training, an enterprise SIEM, or an LMS.

---

## Repository structure

```
security-pulse/
├── apps/
│   ├── mobile/          # Flutter app (iOS, iPadOS, Android)
│   └── admin-web/       # Next.js admin portal (TypeScript)
├── services/
│   ├── api/             # FastAPI backend (Python)
│   └── worker/          # Background job worker (Python)
├── packages/
│   ├── api-contract/    # OpenAPI 3.1 specification (source of truth)
│   └── design-tokens/   # Shared design tokens (JSON)
├── infrastructure/      # IaC and environment configs
├── docs/
│   ├── adr/             # Architecture Decision Records
│   ├── diagrams/        # Architecture diagrams
│   ├── content-guidelines/
│   └── operations/
└── .github/workflows/   # CI/CD pipelines
```

---

## Prerequisites

| Tool | Minimum version | Install |
|---|---|---|
| Flutter | 3.24.x (stable) | https://docs.flutter.dev/get-started/install |
| Dart | 3.5.x (bundled with Flutter) | Bundled |
| Xcode | 15.x | App Store (macOS only) |
| Android Studio | 2024.x | https://developer.android.com/studio |
| Node.js | 20 LTS | https://nodejs.org |
| Python | 3.12+ | https://python.org |
| Docker + Compose | Latest stable | https://docs.docker.com/get-docker |
| Git | 2.40+ | https://git-scm.com |

---

## Quick start

### 1. Clone and configure environment

```bash
git clone <repo-url> security-pulse
cd security-pulse
cp .env.example .env
# Edit .env — see comments inside for required values
```

### 2. Start local backend services

```bash
docker compose up -d
```

This starts PostgreSQL, Redis, and the FastAPI API with a mock identity provider. The mock identity provider is disabled automatically when `APP_ENV=production`.

### 3. Run the backend API

```bash
cd services/api
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -e ".[dev]"
alembic upgrade head
uvicorn app.main:app --reload --port 8000
```

Health check: http://localhost:8000/health

In development mode (`APP_ENV=development`), 5 published scenarios are automatically seeded on startup. These provide immediate test data for the daily scenario flow without manual setup.

### 4. Run the admin portal

```bash
cd apps/admin-web
npm install
npm run dev
```

Admin portal: http://localhost:3000

### 5. Run the Flutter mobile app

```bash
cd apps/mobile
flutter pub get
flutter run
```

### 6. Run all tests

```bash
# Backend
cd services/api && pytest

# Admin portal
cd apps/admin-web && npm test

# Flutter
cd apps/mobile && flutter test
```

---

## Environment variables

See `.env.example` for all variables and documentation. Never commit `.env`.

Key variables:

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `REDIS_URL` | Redis connection string |
| `OIDC_ISSUER_URL` | Corporate identity provider discovery URL |
| `OIDC_CLIENT_ID` | OAuth2 client ID |
| `OIDC_AUDIENCE` | OAuth2 audience (optional, defaults to `OIDC_CLIENT_ID`) |
| `APP_ENV` | `development` or `production` |
| `ALLOW_MOCK_AUTH` | `true` only when `APP_ENV=development` |

---

## Authentication (Phase 2)

The app uses OIDC Authorization Code Flow with PKCE for authentication. In development, mock auth is enabled by default (`ALLOW_MOCK_AUTH=true`), which accepts mock tokens without a real identity provider.

**Mock auth tokens** (development only):
- `mock-employee` — signs in as a test employee
- `mock-content_admin` — signs in as a content admin
- `mock-security_admin` — signs in as a security admin

**Production** requires `OIDC_ISSUER_URL` and `OIDC_CLIENT_ID` to be set. Mock auth is blocked when `APP_ENV=production`.

For backend API auth testing:
```bash
# With mock auth enabled
curl -H "Authorization: Bearer mock-employee" http://localhost:8000/api/v1/auth/me
```

---

## Scenario delivery (Phase 3)

The backend serves daily scenarios via the following endpoints (all require authentication):

| Endpoint | Description |
|---|---|
| `GET /api/v1/scenarios/today` | Today's assigned scenario (answer correctness hidden) |
| `GET /api/v1/scenarios/{id}` | Single scenario by ID |
| `POST /api/v1/scenarios/{id}/responses` | Submit an answer (idempotent via `Idempotency-Key`) |
| `GET /api/v1/scenarios/{id}/result` | Correctness and explanation (only after submission) |
| `GET /api/v1/me/history` | Paginated response history for the authenticated user |
| `GET /api/v1/me/progress` | Streak, total answered, and accuracy stats |

Seed data (5 published scenarios) is loaded automatically when `APP_ENV=development`.

---

## Governance decisions

Seventeen decisions must be made before production. See `ARCHITECTURE.md § Governance decisions` for the full list. Current status: all unresolved (see each item for owner and deadline).

---

## Related documents

| Document | Purpose |
|---|---|
| `PRODUCT_SPEC.md` | Full product requirements |
| `ARCHITECTURE.md` | Architecture, data flows, ADRs |
| `SECURITY.md` | Security controls and requirements |
| `THREAT_MODEL.md` | Threats, trust boundaries, mitigations |
| `API_CONTRACT.md` | API reference (→ `packages/api-contract/openapi.yaml`) |
| `TEST_STRATEGY.md` | Testing approach by layer |
| `RUNBOOK.md` | Operational procedures |
| `CONTRIBUTING.md` | How to contribute |
| `CHANGELOG.md` | Version history |
| `CLAUDE.md` | Claude Code agent instructions |
| `AGENTS.md` | Codex agent instructions |
