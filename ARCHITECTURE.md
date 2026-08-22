# Architecture

**Security Pulse — Architecture Document**  
Version: 1.0 | Status: Draft

---

## System overview

Security Pulse is a multi-tier mobile-first platform:

```
┌─────────────────────┐     ┌──────────────────────┐
│  Flutter Mobile App │     │  Admin Web Portal     │
│  iOS / iPad / Android│     │  Next.js / TypeScript │
└──────────┬──────────┘     └──────────┬────────────┘
           │  HTTPS + OIDC Bearer token │
           └───────────────┬────────────┘
                           │
                  ┌────────▼─────────┐
                  │  FastAPI Backend │
                  │  REST / OpenAPI  │
                  └──┬────┬────┬─────┘
                     │    │    │
         ┌───────────┘    │    └──────────────┐
         │                │                   │
┌────────▼───────┐ ┌──────▼──────┐  ┌────────▼────────┐
│  PostgreSQL    │ │  Redis      │  │  Notification   │
│  Core data     │ │  Cache/rate │  │  Worker         │
└────────────────┘ └─────────────┘  └─────────────────┘

iOS Widget:
  WidgetKit TimelineProvider
  → reads DailyCardModel from App Group UserDefaults
  → deep-links to Flutter app via securitypulse:// scheme

Android Widget:
  Jetpack Glance AppWidget
  → reads DailyCardModel from SharedPreferences
  → deep-links to Flutter app via securitypulse:// scheme
```

---

## Layers and responsibilities

| Layer | Technology | Responsibility |
|---|---|---|
| Mobile app | Flutter + Dart | UI, navigation, secure token storage, widget bridge |
| iOS widget | SwiftUI + WidgetKit | Non-sensitive daily card display, deep link |
| Android widget | Kotlin + Jetpack Glance | Non-sensitive daily card display, deep link |
| Admin portal | Next.js + TypeScript | Content authoring, analytics, campaign management |
| API | FastAPI + Python | Auth, business logic, data access, OpenAPI contract |
| Database | PostgreSQL | Persistent storage |
| Cache | Redis | Short-lived cache, rate limiting |
| Worker | Python (Celery or ARQ TBD) | Push notifications, scheduled publishing, exports |
| Secrets | Approved secrets manager (TBD) | All credentials; never in code or env files committed |

---

## Trust boundaries

1. **Public internet → API**: All requests authenticated with short-lived OIDC bearer tokens. No endpoint is unauthenticated except `/health` and `/health/ready`.
2. **API → Database**: Internal network only. Database credentials in secrets manager.
3. **Flutter app → iOS widget**: App Group shared storage. Only non-sensitive `DailyCardModel` is written. No auth tokens.
4. **Flutter app → Android widget**: SharedPreferences with widget-scoped key prefix. Same data restrictions.
5. **Widget → API**: Widgets make no authenticated API calls. The parent app fetches and writes the cache.
6. **Admin portal → API**: Same OIDC bearer token; role must include `author`, `reviewer`, `approver`, or `platform_admin`.
7. **Worker → Database**: Internal network. Separate service account with minimum required privileges.

---

## Widget data contract

The `DailyCardModel` written to shared storage contains only:

```json
{
  "scenarioId": "uuid-string",
  "title": "Short scenario title (max 80 chars)",
  "completionState": "available | completed | no_assignment | offline | signed_out",
  "deepLinkRoute": "/scenarios/{scenarioId}",
  "expiresAt": "2025-01-01T00:00:00Z"
}
```

**Prohibited fields**: auth tokens, `is_correct`, `explanation`, employee identifiers, department, incident data, PII.

---

## Authentication and authorization

- Mobile: OIDC Authorization Code Flow with PKCE via `flutter_appauth` (implemented in Phase 2).
- Admin portal: OIDC Authorization Code Flow via server-side session.
- Token storage on mobile: `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android).
- Widget storage: App Group (iOS), SharedPreferences (Android). No tokens ever stored here.
- Full platform roles: `employee`, `author`, `reviewer`, `approver`, `soc_analyst`, `platform_admin`.
- Phase 2 roles (implemented): `employee`, `content_admin`, `security_admin`. Additional roles will be added with the admin portal.
- All role checks are enforced server-side. Client role state is display-only.
- Auth provider strategy pattern: `OIDCAuthProvider` (production) and `MockAuthProvider` (development only, gated by `ALLOW_MOCK_AUTH=true` + `APP_ENV != production`).
- JIT user provisioning: on first valid OIDC sign-in, a user record is auto-created with `role=employee`. Admin roles are assigned manually.
- Stateless JWT: no server-side session store in Phase 2. Logout clears tokens on the client. Redis token denylist is a documented future enhancement.
- GoRouter auth guard redirects unauthenticated users to sign-in and prevents authenticated users from accessing the sign-in screen.

---

## API conventions

- Base path: `/api/v1`
- Authentication: `Authorization: Bearer <access_token>` on all protected endpoints.
- Idempotency: `Idempotency-Key: <uuid>` header on mutating operations.
- Correlation: `X-Correlation-Id` header in every request and response.
- Pagination: `?page=1&page_size=20` on list endpoints.
- Error envelope: `{ "code": "string", "message": "string", "details": {}, "correlationId": "string" }`
- Breaking changes require a new API version (`/api/v2`).

---

## Data flows

### Daily question flow (implemented in Phase 3)
```
Employee opens app
  → Flutter checks auth → GoRouter guards route
  → GET /api/v1/scenarios/today → returns scenario without is_correct (T-03: AnswerOptionForEmployee schema)
  → Employee selects answer → POST /api/v1/scenarios/{id}/responses (with Idempotency-Key)
  → Backend records Response, enforces unique(user_id, scenario_id) via UniqueConstraint + idempotency_key (T-04)
  → All queries filter by authenticated user_id (T-02)
  → GET /api/v1/scenarios/{id}/result → returns is_correct + explanation (AnswerOptionWithResult schema)
  → Flutter writes DailyCardModel{completionState: completed} to shared storage
  → Platform channel: WidgetCenter.reloadAllTimelines() (iOS) / widget update (Android)
```

**Backend models (Phase 3):** Scenario, AnswerOption, Assignment, Response, Campaign, AuditEvent — defined as SQLAlchemy ORM models with Alembic migration `0002`.

**Additional employee endpoints (Phase 3):**
- `GET /api/v1/me/history` — paginated response history
- `GET /api/v1/me/progress` — streak, total answered, accuracy

**Flutter (Phase 3):** `ApiScenarioRepository` (Dio-based), history screen, progress provider, `ResponseRecord` and `UserProgress` models with `fromJson` factories.

### Widget bridge data flow (implemented in Phase 5)
```
Scenario state changes in Flutter
  → widgetSyncProvider (Riverpod ref.listen) detects change
  → widget_state_mapper maps DailyScenarioState to DailyCardBridgeModel
  → PlatformWidgetBridge calls MethodChannel('com.securitypulse/widget_bridge')
  → Android: WidgetBridgePlugin writes JSON to SharedPreferences("security_pulse_widget")
    → triggers AppWidgetManager broadcast → Glance DailyCardWidget re-renders
  → iOS: WidgetBridgePlugin writes JSON to UserDefaults("group.com.securitypulse.shared")
    → triggers WidgetCenter.shared.reloadAllTimelines() → WidgetKit re-renders

Auth sign-out:
  → widgetSyncProvider detects AuthUnauthenticated
  → writes DailyCardBridgeModel(completionState: "signed_out", deepLinkRoute: "/signin")
  → widget shows "Sign in to see today's question"
```

### Notification architecture (implemented in Phase 5)
```
NotificationService (abstract)
  ├── LocalNotificationService (dev: flutter_local_notifications)
  └── [FcmNotificationService] (production: Firebase Cloud Messaging — future)

NotificationPreferenceNotifier (Riverpod)
  → reads/writes preference to flutter_secure_storage
  → calls NotificationService.scheduleDailyReminder() or cancelDailyReminder()
  → Settings screen: SwitchListTile toggle

Daily notification (static, non-sensitive):
  Title: "Security Pulse"
  Body: "Your daily security challenge is ready"
  Schedule: 9:00 AM local time, daily repeating
  Tap action: deep link securitypulse:///today
```

### Deep link handling (implemented in Phase 5)
```
Widget/notification tap → securitypulse:///today
  → Android: intent-filter routes to MainActivity
  → iOS: CFBundleURLTypes routes to Runner
  → GoRouter receives path /today
  → Redirect route: /today → RoutePaths.home
  → Auth guard: if unauthenticated → redirect to /sign-in
  → If authenticated → DailyScenarioScreen
```

Accepted deep link paths (whitelist):
- `/today` → home screen (daily scenario)
- `/progress` → history screen
- `/signin` → sign-in screen
- All other paths → rejected (fail safe)

### Incident report flow (Phase 4)
```
Employee taps "Report" FAB on daily scenario screen
  → Flutter renders incident form with CredentialWarningBanner (always visible)
  → Form fields: report type (9 categories), title, description, date/time picker,
    severity (radio buttons), conditional fields (type-specific: sender_or_url,
    system_affected, device_type+location, data_classification)
  → UrgentGuidanceBanner shown when severity=critical or type=unauthorized_access|data_exposure
  → POST /api/v1/incidents (with Idempotency-Key header)
  → Backend validates: Pydantic schema rejects credential patterns, validates metadata keys
  → Service layer: idempotency check → rate limit (max 10/hour/user) → persist IncidentReport
  → Fire-and-forget routing via LogOnlyIncidentRouter (future: email, webhook, ServiceNow)
  → 201 Created → Flutter shows receipt (report ID, title, type, timestamp)
  → GET /api/v1/incidents/mine → paginated report history (user-scoped)
  → GET /api/v1/incidents/{id} → report detail (user-scoped, 404 for other users)
```

**Backend models (Phase 4):** IncidentReport with ReportType (9 values), IncidentSeverity, IncidentStatus — defined as SQLAlchemy ORM model with Alembic migration `0003`. JSONB `metadata_json` column stores type-specific conditional fields.

**Flutter (Phase 4):** `MockIncidentRepository` (default) and `ApiIncidentRepository` (Dio-based). Riverpod `IncidentFormNotifier` (AutoDispose) with sealed state hierarchy. 5 presentation widgets, 3 screens, ~35 localization keys.

---

## Technology decisions (ADR index)

| ADR | Decision | Status |
|---|---|---|
| ADR-0001 | Technology stack | Approved (see `docs/adr/ADR-0001-tech-stack.md`) |
| ADR-0002 | State management: Riverpod 2 | Draft |
| ADR-0003 | Navigation: GoRouter | Draft |
| ADR-0004 | HTTP client: Dio + Retrofit | Draft |
| ADR-0005 | Worker: ARQ vs Celery | Pending |
| ADR-0006 | Notification provider | Pending (governance decision #12) |
| ADR-0007 | Secrets manager | Pending (governance decision #3) |

---

## Governance decisions (17 open)

All must be resolved before production. See `PRODUCT_SPEC.md § 18` for the full list.

| # | Decision | Owner | Status |
|---|---|---|---|
| 1 | Product owner and funding owner | — | Unresolved |
| 2 | Approved identity provider | — | Unresolved |
| 3 | Approved cloud and database region | — | Unresolved |
| 4 | Approved MDM and app distribution | — | Unresolved |
| 5 | Approved ticketing integration | — | Unresolved |
| 6 | Data retention periods | — | Unresolved |
| 7 | Countries and languages | — | Unresolved |
| 8 | Works-council requirements | — | Unresolved |
| 9 | Individual response visibility | — | Unresolved |
| 10 | Minimum group size for analytics | — | Unresolved |
| 11 | Reward approval and tax handling | — | Unresolved |
| 12 | Attachment policy | — | Unresolved |
| 13 | Supported OS versions | — | Unresolved |
| 14 | Accessibility standard | — | Unresolved |
| 15 | Incident emergency wording | — | Unresolved |
| 16 | Operational support team and SLA | — | Unresolved |
| 17 | Business continuity requirements | — | Unresolved |
