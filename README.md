# Security Pulse

> Daily cybersecurity practice that people can finish—and security teams can govern.

Security Pulse is a mobile-first security-awareness platform for organizations that want to turn one-off training into a lightweight daily habit. Employees receive a short, role-aware scenario, make a decision in under a minute, and immediately learn why it matters. Security and GRC teams can author content, manage campaigns, review privacy-protected analytics, and retain an administrative audit trail.

Built for iOS, iPadOS, Android, and the web.

## Why Security Pulse

Most security training is occasional, long, and easy to forget. Security Pulse makes practice timely and repeatable:

- **For employees:** a daily challenge, immediate explanation, progress history, notifications, home-screen widgets, and a structured way to report suspicious activity.
- **For security teams:** governed content workflows, campaigns, aggregate analytics, reward-eligibility calculations, and auditable administrative actions.
- **For the organization:** a deliberately narrow data model that avoids credential collection, hides answers before submission, and suppresses small analytics groups.

Security Pulse is an awareness and reporting companion—not a replacement for an LMS, SIEM, or incident-response platform.

## Product at a glance

| Employee experience | Security-team experience |
| --- | --- |
| Complete a short daily scenario | Author, review, approve, and publish scenarios |
| Receive an explanation immediately after answering | Create campaigns and calculate eligibility rules |
| Use an iOS or Android home-screen widget | Review group-suppressed analytics |
| Report suspicious activity without sharing credentials | Inspect administrative audit events |
| Track progress, streaks, and history | Prepare governed exports and downstream routing |

## What is in this repository

```text
apps/
  mobile/          Flutter app for iOS, iPadOS, and Android
  admin-web/       Next.js portal for content, campaigns, and analytics
services/
  api/             FastAPI REST API, PostgreSQL models, and Alembic migrations
  worker/          Background-job foundation for scheduled work and notifications
packages/
  api-contract/    OpenAPI 3.1 contract—the API source of truth
  design-tokens/   Shared visual design tokens
docs/
  adr/             Architecture decision records
infrastructure/    Environment and deployment configuration
```

## Architecture

```text
Flutter mobile app ──┐
                     ├── HTTPS + OIDC ──> FastAPI API ──> PostgreSQL
Next.js admin portal ┘                           │
                                                 ├── Redis (cache / rate limiting)
iOS WidgetKit + Android Glance <── non-sensitive │
widget bridge data from the mobile app            └── Worker (scheduled jobs)
```

The API contract is versioned in [`packages/api-contract/openapi.yaml`](packages/api-contract/openapi.yaml). Native widgets never make authenticated API calls; they receive a deliberately minimal card model from the parent app.

## Security is a product feature

The system is designed to make the safe path the default:

- OIDC Authorization Code Flow with PKCE and secure mobile token storage.
- Server-enforced, deny-by-default role-based authorization.
- Database-enforced idempotency for scenario responses and incident reports.
- Separate employee and result schemas so answer correctness cannot be returned before submission.
- No passwords, MFA codes, access tokens, or sensitive incident bodies in logs.
- Widgets store only a title, display state, route, and expiry—never tokens, PII, answers, or incident data.
- Analytics are aggregated with small-group suppression.

Read the complete [security requirements](SECURITY.md) and [threat model](THREAT_MODEL.md) before deploying or integrating the platform.

## Local development

### Prerequisites

- Flutter 3.24+ and the platform toolchains needed for the target device
- Node.js 20+
- Python 3.11+
- Docker and Docker Compose

### 1. Configure the workspace

```bash
git clone <repo-url> security-pulse
cd security-pulse
cp .env.example .env
```

Do not commit `.env` files or secrets. Local Docker configuration contains development-only credentials and must never be used in staging or production.

### 2. Start PostgreSQL, Redis, and the API

```bash
docker compose up -d
curl http://localhost:8000/health
```

For a non-container API workflow:

```bash
cd services/api
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
alembic upgrade head
uvicorn app.main:app --reload --port 8000
```

### 3. Start the admin portal

```bash
cd apps/admin-web
npm install
npm run dev
```

The portal runs at [http://localhost:3000](http://localhost:3000).

### 4. Run the mobile app

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Validate changes

Run the checks for the components you change before opening a pull request:

```bash
# API
cd services/api
ruff check .
mypy app
pytest

# Admin portal
cd apps/admin-web
npm run lint
npm run type-check
npm test

# Mobile app
cd apps/mobile
flutter analyze
flutter test
```

## Delivery status

The repository contains the core experience and platform foundations: authentication and authorization patterns, scenario delivery, native-widget bridging, notification preferences, incident reporting, administrative analytics and campaigns, and audit-event persistence.

Security Pulse is **pre-pilot software**, not a production deployment. Several enterprise decisions remain intentionally open, including the identity provider, hosting region, secrets manager, notification provider, ticketing integration, retention, support model, and business-continuity plan. See [Architecture: governance decisions](ARCHITECTURE.md#governance-decisions) and the [runbook](RUNBOOK.md) for the current operational posture.

Some development experiences use local or mock service implementations until a production environment and approved integrations are available. Do not enable mock authentication in production.

## Engineering principles

1. **Trust is earned in the details.** Never collect credentials; minimize retained data; make data flows explicit.
2. **Authorization belongs on the server.** Client state is presentation, not permission.
3. **A correct answer is protected until it is earned.** Employee scenario responses cannot reveal correctness before submission.
4. **Operationally boring beats clever.** Versioned APIs, Alembic migrations, idempotent writes, correlation IDs, and explicit rollback procedures.
5. **Human governance stays in the loop.** AI-generated content is not published automatically, and rewards remain subject to HR, Legal, Tax, and Ethics approval.

## Documentation

| Document | Start here when you need to… |
| --- | --- |
| [Product specification](PRODUCT_SPEC.md) | Understand users, scope, exclusions, and product flows |
| [Architecture](ARCHITECTURE.md) | Review system design, trust boundaries, and decisions |
| [API contract](API_CONTRACT.md) | Work with the versioned REST API and OpenAPI workflow |
| [Security requirements](SECURITY.md) | Review required security controls |
| [Threat model](THREAT_MODEL.md) | Understand risks and mitigations |
| [Test strategy](TEST_STRATEGY.md) | Choose coverage and quality gates |
| [Runbook](RUNBOOK.md) | Operate local environments and database migrations |
| [Architecture decisions](docs/adr/) | Review accepted and pending technical decisions |
| [Contributing guide](CONTRIBUTING.md) | Prepare a change for human review |

## Contributing

Changes should be small, reviewed by a human, and accompanied by appropriate tests. For changes to a public API, security boundary, persistence model, or operational behavior, update the relevant contract, threat model, runbook, and/or ADR in the same pull request.

Never merge directly to the default branch without the required review and checks.

---

**Questions or pilot interest?** Start with the product and governance documentation above; deployment and enterprise integration decisions must be approved before production use.
