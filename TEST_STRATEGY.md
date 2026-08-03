# Test Strategy

**Security Pulse — Test Strategy**  
Version: 1.0 | Status: Draft

---

## Principles

- Every behavior change requires a test.
- Tests run in CI on every pull request.
- Authorization is tested, not assumed.
- Negative paths are as important as happy paths.
- No test may contain real credentials, PII, or production URLs.

---

## Backend (FastAPI + Python)

| Type | Tool | Coverage target |
|---|---|---|
| Unit | pytest | Business logic, assignment engine, eligibility |
| Integration | pytest + httpx TestClient | Every API endpoint, every HTTP status code |
| Authorization matrix | pytest | Each endpoint × each role × allowed/denied |
| Database migration | pytest + Alembic | Upgrade and downgrade for each migration |
| Idempotency | pytest | Duplicate response and incident submission |
| Concurrency | pytest-asyncio | Concurrent answer submissions for same user+scenario |
| Contract | schemathesis or dredd | Responses match OpenAPI spec |
| Load | locust | Daily notification spike (target: 10k employees in 5 minutes) |
| Security | bandit, pip-audit | CI gate: no unreviewed HIGH findings |

### Required test fixtures
- Mock OIDC token factory (each role)
- Scenario factory (draft, approved, published)
- User factory (each role profile)
- Assignment factory

---

## Flutter mobile

| Type | Tool | Coverage target |
|---|---|---|
| Unit | flutter_test | Use cases, state machines, data mappers |
| Widget | flutter_test | Every screen × every state (loading, empty, error, offline, unauthorized) |
| Integration | patrol or integration_test | Sign-in, daily scenario, incident report |
| Deep link | integration_test | Deep link before auth, during auth, after auth |
| Offline/retry | flutter_test + mock HTTP | Network failure handling, retry behavior |
| Secure storage | mocktail | Token read/write/clear |
| Accessibility | flutter_test + SemanticsDebugger | Semantics labels on all interactive elements |
| Localization | flutter_test | ARB keys resolve; no overflow on 2× string length |

---

## Native widgets

| Test scenario | iOS (XCTest) | Android (JUnit) |
|---|---|---|
| Small, medium, large size | ✓ | ✓ |
| Signed-in, signed-out state | ✓ | ✓ |
| Assigned, no-assignment state | ✓ | ✓ |
| Completed, incomplete state | ✓ | ✓ |
| Network unavailable | ✓ | ✓ |
| Stale cached content | ✓ | ✓ |
| Deep link generation | ✓ | ✓ |
| No sensitive data in storage | ✓ | ✓ |

---

## Admin portal (Next.js)

| Type | Tool | Coverage target |
|---|---|---|
| Component | Jest + Testing Library | All components × all states |
| Integration | Playwright or Cypress | Full authoring, review, publish workflow |
| Role-based route | Jest | Each route × each role |
| Autosave | Jest | Draft save, conflict, recovery |
| Analytics suppression | Jest | Small-group data not rendered |
| Accessibility | axe-core | No WCAG 2.2 AA violations |

---

## Security gates (CI-enforced)

- Secret scanning (gitleaks or GitHub secret scanning)
- Dependency scanning (pip-audit, npm audit)
- SAST (bandit, eslint security plugin)
- Container scanning (trivy)
- No HIGH/CRITICAL findings without reviewed exception

---

## Definition of done

A feature is complete only when all of the following are true:

1. Acceptance criteria are met
2. Code reviewed by a human
3. Tests added and passing in CI
4. Authorization tested (not just happy path)
5. Failure states implemented (error, offline, empty, unauthorized)
6. Accessibility checked
7. All user-visible strings use localization keys
8. API and architecture documentation updated
9. Threat model updated if data flows changed
10. No sensitive data in logs
11. Migration and rollback instructions exist when applicable
12. Product owner has accepted the behavior
