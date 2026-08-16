# Security

**Security Pulse — Security Requirements and Controls**  
Version: 1.0 | Status: Draft

---

## Authentication

- OIDC Authorization Code Flow with PKCE on mobile (implemented in Phase 2).
- Short-lived access tokens (target: 15 minutes; governance decision required).
- Refresh tokens stored in `flutter_secure_storage` (Keychain / EncryptedSharedPreferences).
- Server validates every token on every request. No client-trusted role checks.
- Separate RBAC roles: `employee`, `author`, `reviewer`, `approver`, `soc_analyst`, `platform_admin`.
- Phase 2 roles (implemented): `employee`, `content_admin`, `security_admin`.
- Deny by default: every protected endpoint returns `403` unless an explicit allow rule matches.
- Reauthentication required for high-risk admin actions (configurable).

### Phase 2 auth safety controls (implemented)

- **Mock auth gating**: `MockAuthProvider` only activates when `ALLOW_MOCK_AUTH=true` AND `APP_ENV != production`. A startup assertion in `main.py` (`_assert_production_safety()`) rejects misconfiguration.
- **Token never logged**: Auth service, audit service, and HTTP dependencies never log token values. Structured audit events log user_id and event type only.
- **No tokens in SharedPreferences**: `SecureTokenStorage` uses `flutter_secure_storage` with `AndroidOptions(encryptedSharedPreferences: true)` and `IOSOptions(accessibility: first_unlock)`.
- **401 handling**: Dio interceptor detects 401 responses, attempts token refresh, and triggers sign-out on refresh failure.
- **RBAC dependency**: `require_role(*allowed_roles)` FastAPI dependency returns 403 for unauthorized role access.

### Phase 3 scenario delivery security controls (implemented)

- **T-02 — User-scoped queries**: All scenario, assignment, and response queries filter by `user_id` from the authenticated token. The service layer enforces that users can only access their own assignments and submit responses to scenarios assigned to them.
- **T-03 — Answer exposure prevention**: Separate Pydantic schemas enforce the pre/post-submission boundary. `AnswerOptionForEmployee` (used in GET /scenarios/today and GET /scenarios/{id}) excludes `is_correct` and `explanation`. `AnswerOptionWithResult` (used in GET /scenarios/{id}/result) includes them. It is structurally impossible for the pre-submission schema to leak correctness.
- **T-04 — Duplicate response prevention**: A `UniqueConstraint` on `(user_id, scenario_id)` in the Response table prevents duplicate answers at the database level. An `idempotency_key` column on Response supports safe client retries. The service layer checks for existing responses before insertion.

### Phase 4 incident reporting security controls (implemented)

- **T-02 — User-scoped incident queries**: All incident report queries filter by `reporter_id == current_user.id`. GET /incidents/{id} returns 404 (not 403) when a report belongs to another user, preventing information disclosure about report existence.
- **T-11 — Credential rejection**: No password or MFA fields exist in the incident form. A `CredentialWarningBanner` is always visible on the form. Backend `IncidentReportCreate` schema uses regex-based `reject_credential_patterns` validator to detect and reject password/MFA/API key patterns in descriptions. Metadata fields are validated against `_FORBIDDEN_METADATA_KEYS` (password, auth_token, mfa_code, api_key, secret_key, access_token, refresh_token).
- **T-14 — Rate limiting**: DB-based rate limiting enforces max 10 incident reports per user per hour. The service layer runs `SELECT COUNT(*) WHERE reporter_id = :uid AND created_at > now() - interval '1 hour'` before each creation. Returns HTTP 429 when limit exceeded. Idempotent replays (via `Idempotency-Key` header) do not count against the rate limit.

---

## Data minimization

- Collect only data required for awareness, assignment, reporting, and approved analytics.
- No passwords, MFA codes, contact lists, microphone, photos, or device location.
- Department-level analytics preferred over individual-level.
- Incident report: no credential fields. App must display "Never enter your password or MFA code."
- Attachments: disabled by default. Governed by retention and malware-scanning rules.

## Application security controls

| Control | Requirement |
|---|---|
| Transport | TLS 1.2+ on all connections |
| Storage encryption | Encryption at rest for PostgreSQL and Redis |
| Secrets management | Approved secrets manager only. No secrets in code, config files, or env files committed to git |
| Input validation | All inputs validated with Pydantic server-side |
| Output encoding | All outputs encoded to prevent XSS |
| SQL injection | Parameterized queries via SQLAlchemy ORM only |
| CSRF | CSRF tokens on admin portal state-changing requests |
| Rate limiting | Rate limiting on auth and submission endpoints via Redis |
| Security headers | HSTS, CSP, X-Frame-Options, X-Content-Type-Options |
| Dependency scanning | Automated in CI (pip-audit, npm audit, snyk or equivalent) |
| SAST | Automated in CI (bandit for Python, eslint security plugin for JS) |
| Container scanning | Automated in CI |
| Mobile token storage | `flutter_secure_storage` only. No plain SharedPreferences for tokens |
| Widget storage | Non-sensitive DailyCardModel only. No tokens |
| Rooted/jailbroken | Follow corporate MDM policy (governance decision required) |
| Crash reports | No sensitive data in crash reports or logs |

## Audit requirements

**Record:**
- Sign-in events and auth failures
- Administrative authorization failures
- Content creation, review, approval, publishing, and retirement
- Campaign rule changes
- Analytics exports
- Integration configuration changes
- Incident status changes

**Never record:**
- Access tokens or refresh tokens
- Passwords or MFA codes
- Complete incident message bodies
- Sensitive attachment content

## Retention

Retention periods require approval from Privacy, Legal, HR, Security, and regional stakeholders. The following categories must be governed separately:

- Awareness response data
- Incident report data
- Administrative audit log data
- Operational log data

## Security review gates

Before each phase promotion:
- Manual authorization matrix review
- SAST scan results reviewed
- Dependency scan results reviewed
- Threat model updated for new data flows
- No high or critical findings without accepted risk

Before production:
- Mobile binary review
- Container scan
- Penetration test or security architecture review (governance decision required)
