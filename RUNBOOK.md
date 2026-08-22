# Runbook

**Security Pulse — Operational Runbook**  
Version: 1.0 | Status: Draft (pre-pilot)

---

## Local development

See `README.md § Quick start`.

---

## Services

| Service | Default port | Health check |
|---|---|---|
| FastAPI API | 8000 | GET /health |
| PostgreSQL | 5432 | pg_isready |
| Redis | 6379 | redis-cli ping |
| Admin portal | 3000 | GET / |

---

## Database migrations

```bash
# Apply all pending migrations
cd services/api && alembic upgrade head

# Roll back one migration
cd services/api && alembic downgrade -1

# Show migration history
cd services/api && alembic history

# Generate a new migration (after model changes)
cd services/api && alembic revision --autogenerate -m "describe change"
```

**Warning:** Always review auto-generated migration files before applying. Never run `alembic upgrade head` on production without human review.

---

## Environment management

- Development: `docker compose up -d`
- Staging / Production: deployment procedure TBD (governance decision #3 — cloud platform unconfirmed)

---

## Mock authentication

Mock authentication is available in development only. It is controlled by:

```
APP_ENV=development
ALLOW_MOCK_AUTH=true
```

The API startup check enforces: if `APP_ENV=production` and `ALLOW_MOCK_AUTH=true`, the service refuses to start.

To sign in with mock auth in development, use the header `X-Mock-User-Id` with the user ID and `X-Mock-User-Role` with the role.

---

## Backup and restore

Procedure: TBD (governance decision #3 and #17).

---

## Incident response

If a security incident is suspected:
1. Notify the security team immediately (contact TBD, governance decision #16).
2. Do not attempt to investigate alone.
3. Preserve logs.
4. Governance decision #16 must confirm the SLA and escalation path.

---

## Known unresolved items

All 17 governance decisions in `ARCHITECTURE.md` are unresolved. This runbook will be updated as decisions are made.
