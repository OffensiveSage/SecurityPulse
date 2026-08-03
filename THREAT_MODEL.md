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
| T-02 | Horizontal privilege escalation (accessing another user's responses) | API | High | Server enforces `response.user_id == authenticated_user_id` |
| T-03 | Answer exposure before submission | API | Medium | `is_correct` stripped from GET /scenarios/{id}; only available from GET /scenarios/{id}/result after response recorded |
| T-04 | Duplicate response submission | API/DB | Medium | Unique constraint on `(user_id, scenario_id)`; idempotency key |
| T-05 | Deep link tampering (widget) | Mobile | Medium | Backend validates ownership; `scenarioId` in deep link does not grant access without valid token |
| T-06 | Sensitive data in widget storage | iOS/Android widget | High | Only `DailyCardModel` with title, state, deepLinkRoute written; no tokens, no PII |
| T-07 | Token extraction from widget storage | iOS/Android widget | High | Tokens never written to App Group or SharedPreferences |
| T-08 | Admin role escalation | API | High | RBAC enforced server-side; claims from trusted IdP only |
| T-09 | Content published without approval | API | Medium | State machine enforces draft→review→approved→published; each transition requires appropriate role |
| T-10 | Individual re-identification via analytics | API | Medium | Minimum group size suppression; preference for aggregate data |
| T-11 | Credential submission via incident form | Mobile | High | No password/MFA fields; prominent warning displayed; backend rejects submissions with credential patterns |
| T-12 | SQL injection | API | High | SQLAlchemy ORM with parameterized queries only |
| T-13 | Mass assignment / over-posting | API | Medium | Pydantic schema explicitly defines accepted fields |
| T-14 | Rate limit abuse on submission | API | Medium | Redis-backed rate limiting on scenario submission and incident creation |
| T-15 | Stale widget showing incorrect state | iOS/Android widget | Low | `expiresAt` in DailyCardModel; widget shows "offline" state when expired |
| T-16 | Sensitive data in crash reports | Mobile/API | Medium | Crash reporter configured to exclude auth headers, form data |
| T-17 | Mock auth enabled in production | API | Critical | `ALLOW_MOCK_AUTH` gated by `APP_ENV != production`; startup check rejects misconfiguration |
| T-18 | CSRF on admin portal | Admin web | Medium | CSRF tokens on all state-changing requests |

---

## Open risks

- Identity provider not confirmed (governance decision #2). Token validation logic may change.
- Attachment policy not confirmed (governance decision #12). Malware scanning not yet designed.
- Notification provider not confirmed (governance decision #12 extension). Push token handling risk unknown.
- Rooted/jailbroken device policy not confirmed (governance decision #13 extension).

---

## Review cadence

Update this document whenever:
- A new data flow is introduced
- A new external integration is added
- A significant auth or authorization change is made
- A security finding is accepted as a risk

Each update requires a PR with human review.
