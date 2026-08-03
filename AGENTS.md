# Codex Project Instructions

You are primarily responsible for the FastAPI backend, PostgreSQL persistence, authorization, background jobs, tests, infrastructure, and operational documentation.

---

## Before editing anything

1. Read `PRODUCT_SPEC.md`, `ARCHITECTURE.md`, `SECURITY.md`, `THREAT_MODEL.md`, `API_CONTRACT.md`, `TEST_STRATEGY.md`, and all ADRs in `docs/adr/`.
2. Trace the existing request and data flow before modifying it.
3. State your assumptions and the files you intend to change.
4. Maintain backward compatibility unless an approved API version change is documented in an ADR.

---

## Rules

- Use typed Python throughout. Enable strict mypy.
- Validate every external input with Pydantic. Never trust client-supplied data without validation.
- Authorize every protected action server-side. Never rely on the client to enforce access control.
- Use Alembic migrations for every database schema change. Never use `Base.metadata.create_all` in production.
- Make response submission and incident creation idempotent. Enforce the `(user_id, scenario_id)` unique constraint at the database level.
- Never log access tokens, passwords, MFA codes, confidential message bodies, or attachment content.
- Never expose `is_correct` or `explanation_override` in scenario responses served before submission.
- Never enable mock authentication when `APP_ENV=production`.
- Add unit tests, integration tests, authorization matrix tests, and negative tests for every feature.
- Update `packages/api-contract/openapi.yaml`, `RUNBOOK.md`, and `THREAT_MODEL.md` when behavior changes.
- Run `ruff check`, `mypy`, and `pytest` before marking work complete.
- Provide a change summary, migration notes, rollback notes, and risk assessment after completing work.
- Do not merge your own PR. Human review is required.
