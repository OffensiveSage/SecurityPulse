# Threat Model

**Security Pulse — Threat Model**  
Version: 1.0 | Status: Draft

---

## Scope

This threat model covers the Security Pulse MVP: Flutter mobile app, native widgets, FastAPI backend, Next.js admin portal, PostgreSQL, Redis, and the background worker.

---

## Trust boundaries

| Boundary | Description |
|---|---|
| TB-1 | Public internet to API gateway |
| TB-2 | API to PostgreSQL |
| TB-3 | API to Redis |
| TB-4 | Flutter app to iOS widget (App Group) |
| TB-5 | Flutter app to Android widget (SharedPreferences) |
| TB-6 | Worker to API / database |
| TB-7 | Admin portal to API |

---

## Threat actors

| Actor | Motivation | Capability |
|---|---|---|
| Malicious employee | Access others' data, inflate scores | Low–Medium |
| External attacker | Data exfiltration, DoS, credential phishing via fake widget | Medium–High |
| Compromised mobile device | Access widget cache, intercept tokens | Medium |
| Rogue admin | Unauthorized content publishing, data export | Medium |
| Insider SOC analyst | Unauthorized access to incident reports | Medium |

---

## Threats and mitigations

| ID | Threat | Component | Impact | Mitigation |
|---|---|---|---|---|
| T-01 | Auth bypass via token replay | API | High | Short token lifetime, server-side validation, HTTPS only |
| T-02 | Horizontal privilege escalation (accessing another user's responses) | API | High | Server enforces `response.user_id == authenticated_user_id`. **Implemented in Phase 3.** |
| T-03 | Answer exposure before submission | API | Medium | `is_correct` stripped from GET /scenarios/{id}; only available from GET /scenarios/{id}/result after response recorded. **Implemented in Phase 3.** |
| T-04 | Duplicate response submission | API/DB | Medium | Unique constraint on `(user_id, scenario_id)`; idempotency key. **Implemented in Phase 3.** |
| T-05 | Deep link tampering (widget) | Mobile | Medium | Deep link paths validated via whitelist (`/today`, `/progress`, `/signin`); unknown paths rejected. GoRouter auth guard prevents unauthenticated access. **Implemented in Phase 5.** |
| T-06 | Sensitive data in widget storage | iOS/Android widget | High | Only `DailyCardModel` with title, state, deepLinkRoute written; no tokens, no PII. Flutter bridge (`PlatformWidgetBridge`) enforces this structurally. **Implemented in Phase 5.** |
| T-07 | Token extraction from widget storage | iOS/Android widget | High | Tokens never written to App Group or SharedPreferences. `WidgetBridgePlugin` only accepts `DailyCardBridgeModel` JSON — no token fields exist. **Implemented in Phase 5.** |
| T-08 | Admin role escalation | API | High | RBAC enforced server-side; claims from trusted IdP only |
| T-09 | Content published without approval | API | Medium | State machine enforces draft→review→approved→published; each transition requires appropriate role |
| T-10 | Individual re-identification via analytics | API | Medium | Minimum group size suppression; preference for aggregate data |
| T-11 | Credential submission via incident form | Mobile | High | No password/MFA fields; prominent warning displayed; backend rejects submissions with credential patterns. **Implemented in Phase 4.** |
| T-12 | SQL injection | API | High | SQLAlchemy ORM with parameterized queries only |
| T-13 | Mass assignment / over-posting | API | Medium | Pydantic schema explicitly defines accepted fields |
| T-14 | Rate limit abuse on submission | API | Medium | DB-based rate limiting on incident creation (max 10/hour/user); Redis-backed rate limiting planned for scenario submission. **Incident rate limiting implemented in Phase 4.** |
| T-15 | Stale widget showing incorrect state | iOS/Android widget | Low | `expiresAt` in DailyCardModel (set to 2 hours from update); native widgets show "offline" state when expired. Widget timelines refresh hourly. **Implemented in Phase 5.** |
| T-16 | Sensitive data in crash reports | Mobile/API | Medium | Crash reporter configured to exclude auth headers, form data |
| T-17 | Mock auth enabled in production | API | Critical | `ALLOW_MOCK_AUTH` gated by `APP_ENV != production`; startup check (`_assert_production_safety()`) rejects misconfiguration. **Implemented in Phase 2.** |
| T-18 | CSRF on admin portal | Admin web | Medium | CSRF tokens on all state-changing requests |

---

## Phase 2 auth data flow (implemented)

```
Employee opens app
  → AuthNotifier checks SecureTokenStorage for stored tokens
  → If valid tokens exist → AuthAuthenticated state → GoRouter allows access to home
  → If no/expired tokens → AuthUnauthenticated state → GoRouter redirects to /sign-in
  → Employee taps Sign In → flutter_appauth OIDC PKCE flow → IdP returns tokens
  → Tokens stored in flutter_secure_storage (never SharedPreferences)
  → Dio interceptor attaches Bearer token to all API requests
  → On 401 → interceptor attempts token refresh → on failure → AuthUnauthenticated → redirect to /sign-in
  → Sign out → SecureTokenStorage cleared → POST /api/v1/auth/logout (server no-op, stateless JWT)
```

### Mitigations implemented in Phase 2

| Threat | Mitigation status |
|---|---|
| T-01 (Token replay) | Server-side JWT validation with signature, expiry, issuer, audience checks. HTTPS only. |
| T-07 (Token in widget storage) | Tokens stored exclusively in flutter_secure_storage. Widget storage never contains tokens. |
| T-08 (Admin role escalation) | RBAC enforced server-side via `require_role()` dependency. Claims from IdP only. |
| T-17 (Mock auth in production) | `_assert_production_safety()` startup check + dual condition (`ALLOW_MOCK_AUTH=true` AND `APP_ENV != production`). |

## Phase 3 scenario delivery data flow (implemented)

```
Employee opens app
  → Flutter checks auth → GoRouter guards route
  → GET /api/v1/scenarios/today → Pydantic AnswerOptionForEmployee schema (no is_correct)
  → Employee selects answer → POST /api/v1/scenarios/{id}/responses (Idempotency-Key header)
  → Backend: service layer checks user assignment, checks for existing response
  → Database: UniqueConstraint on (user_id, scenario_id) + idempotency_key column
  → GET /api/v1/scenarios/{id}/result → Pydantic AnswerOptionWithResult schema (includes is_correct + explanation)
  → GET /api/v1/me/history → paginated response history (user-scoped)
  → GET /api/v1/me/progress → streak and accuracy stats (user-scoped)
```

### Mitigations implemented in Phase 3

| Threat | Mitigation status |
|---|---|
| T-02 (Horizontal privilege escalation) | All scenario, assignment, and response queries filter by `user_id` from the authenticated token. Service layer enforces user ownership on response submission. |
| T-03 (Answer exposure before submission) | Separate Pydantic schemas: `AnswerOptionForEmployee` (pre-submission, no `is_correct`) vs `AnswerOptionWithResult` (post-submission, includes `is_correct`). Structural enforcement — not runtime stripping. |
| T-04 (Duplicate response submission) | `UniqueConstraint` on `(user_id, scenario_id)` at database level. `idempotency_key` column on Response model for safe retries. Service layer pre-checks for existing responses. |

## Phase 4 incident reporting data flow (implemented)

```
Employee taps "Report" FAB on daily scenario screen
  → Flutter renders incident form (CredentialWarningBanner always visible)
  → No password/MFA fields; UrgentGuidanceBanner shown for critical severity or unauthorized_access/data_exposure
  → Client-side validation: report type required, title 5–100 chars, description 10–2000 chars, occurred_at not future
  → POST /api/v1/incidents (Idempotency-Key header)
  → Backend: Pydantic schema rejects credential patterns in description, validates metadata keys against report type
  → Backend: Service layer checks idempotency key → rate limit (COUNT, max 10/hour) → persist to DB → fire-and-forget router
  → 201 Created (new report) or 200 OK (idempotent replay) or 429 (rate limit exceeded)
  → Flutter shows receipt: report ID (first 8 chars), title, type, timestamp
  → GET /api/v1/incidents/mine → paginated list of user's own reports
  → GET /api/v1/incidents/{id} → detail view (user-scoped, 404 for other users)
```

### Mitigations implemented in Phase 4

| Threat | Mitigation status |
|---|---|
| T-02 (Horizontal privilege escalation) | Incident report queries filter by `reporter_id == current_user.id`. GET /incidents/{id} returns 404 (not 403) for other users' reports, preventing existence disclosure. |
| T-11 (Credential submission via incident form) | No credential fields in form. `CredentialWarningBanner` always visible. Backend `reject_credential_patterns` regex validator on description. `_FORBIDDEN_METADATA_KEYS` set validated on metadata. |
| T-14 (Rate limit abuse on submission) | DB-based rate limiting: `COUNT(*) WHERE reporter_id = :uid AND created_at > now() - interval '1 hour'`. Returns 429 when >= 10 reports in the window. Idempotent replays bypass rate limit check. |

## Phase 5 widget bridge and notification data flow (implemented)

```
Flutter scenario state changes
  → widgetSyncProvider maps state to DailyCardBridgeModel
  → PlatformWidgetBridge sends JSON via MethodChannel
  → Android: SharedPreferences("security_pulse_widget") → Glance DailyCardWidget
  → iOS: UserDefaults("group.com.securitypulse.shared") → WidgetKit SecurityPulseWidget

Widget tap → securitypulse:///today
  → GoRouter validates path via whitelist (/today, /progress, /signin)
  → Auth guard enforces authentication
  → Routes to appropriate screen

Notification tap → opens app via securitypulse:///today
  → Same deep link validation as widget taps
```

### Mitigations implemented in Phase 5

| Threat | Mitigation status |
|---|---|
| T-05 (Deep link tampering) | `deep_link_validator.dart` whitelist accepts only `/today`, `/progress`, `/signin`. Unknown paths return null (rejected). GoRouter auth guard prevents unauthenticated access. Case-insensitive matching. Query params and fragments stripped. |
| T-06 (Sensitive data in widget storage) | `DailyCardBridgeModel` contains only: scenarioId, title, completionState, deepLinkRoute, expiresAt. No token fields, no answer correctness, no PII. Structurally enforced — the model class has no fields for sensitive data. |
| T-07 (Token in widget storage) | `WidgetBridgePlugin` (Android/iOS) only processes `DailyCardBridgeModel` JSON. Token storage (`flutter_secure_storage`) is a completely separate subsystem. No code path connects token storage to widget storage. |
| T-15 (Stale widget state) | `expiresAt` set to 2 hours from last update. Native widgets check expiry and show "offline" fallback. Android updatePeriodMillis=3600000 (1 hour). iOS timeline refresh policy: 1 hour or at model expiry. |
| Notification content leakage | Notification title and body are static strings hardcoded in `LocalNotificationService`. No user data, scenario content, or incident information is included. |
| Malicious deep link navigation | Deep link paths are mapped to internal routes via `DeepLinkPaths` constants. Paths not in the whitelist are silently ignored. Auth guard prevents all unauthenticated access to protected routes. |

---

## Open risks

- Identity provider not confirmed (governance decision #2). Token validation logic may change.
- Attachment policy not confirmed (governance decision #12). Malware scanning not yet designed.
- Notification provider not confirmed (governance decision #12 extension). Push token handling risk unknown.
- Rooted/jailbroken device policy not confirmed (governance decision #13 extension).
- Token denylist not implemented. Stateless JWT means revoked tokens remain valid until expiry. Redis denylist planned for a future phase.

---

## Review cadence

Update this document whenever:
- A new data flow is introduced
- A new external integration is added
- A significant auth or authorization change is made
- A security finding is accepted as a risk

Each update requires a PR with human review.
