# API Contract

The canonical API contract is the OpenAPI 3.1 specification at:

```
packages/api-contract/openapi.yaml
```

This file is the source of truth. All of the following are generated from or
validated against it:

- Flutter Retrofit client (generated via retrofit_generator)
- Backend route validation (validated via schemathesis in CI)
- Admin portal API client types (generated via openapi-typescript)
- API documentation (served at /docs in development)

---

## Quick reference

Base URL: `/api/v1`

| Category | Endpoints |
|---|---|
| Health (no auth) | GET /health, GET /health/ready |
| Auth (implemented) | GET /api/v1/auth/me, POST /api/v1/auth/logout |
| Employee (partially implemented) | GET /me/profile, PATCH /me/preferences, **GET /me/progress** *(impl)*, **GET /me/history** *(impl)* |
| Scenarios (implemented) | **GET /scenarios/today** *(impl)*, **GET /scenarios/{id}** *(impl)*, **POST /scenarios/{id}/responses** *(impl)*, **GET /scenarios/{id}/result** *(impl)* |
| Widget | GET /widget/daily-card |
| Incident reports | POST /incident-reports, GET /incident-reports/{id}/receipt |
| Admin — scenarios | GET/POST /admin/scenarios, PATCH /admin/scenarios/{id}, POST /admin/scenarios/{id}/submit-review \| approve \| publish |
| Admin — analytics | GET /admin/analytics/summary |
| Admin — campaigns | GET/POST /admin/campaigns, POST /admin/campaigns/{id}/calculate-eligibility |
| Admin — audit | GET /admin/audit-events |

---

## API rules

- All protected endpoints require `Authorization: Bearer <token>`.
- Idempotent mutations require `Idempotency-Key: <uuid>`.
- All requests should include `X-Correlation-Id` for tracing.
- All list endpoints are paginated with `?page=1&page_size=20`.
- All errors use the standard `ErrorResponse` envelope: `{ code, message, details, correlation_id }`.
- `is_correct` is never present in scenario responses before submission.
- Breaking changes require a new API version (`/api/v2`).

---

## Updating the contract

1. Edit `packages/api-contract/openapi.yaml`.
2. If adding a new endpoint: create an ADR if it represents a significant feature.
3. Run the backend contract tests: `cd services/api && pytest tests/contract/`.
4. Regenerate the Flutter client: `cd apps/mobile && dart run build_runner build`.
5. Update `API_CONTRACT.md` quick reference table if needed.
6. PR must include both the YAML change and any affected client code.
