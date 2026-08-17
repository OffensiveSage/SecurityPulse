# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Added — Phase 5: Daily Notifications + Native Home-Screen Widget

**Mobile — Widget Bridge**
- Flutter ↔ native widget bridge via MethodChannel (`com.securitypulse/widget_bridge`)
- `DailyCardBridgeModel` with 5 completion states (available, completed, no_assignment, offline, signed_out)
- Android `WidgetBridgePlugin.kt`: writes to `SharedPreferences("security_pulse_widget")`, triggers AppWidget update
- iOS `WidgetBridgePlugin.swift`: writes to App Group `UserDefaults("group.com.securitypulse.shared")`, triggers WidgetKit timeline reload
- `widgetSyncProvider` (Riverpod): auto-updates native widget on scenario or auth state changes
- `widget_state_mapper.dart`: pure functions mapping DailyScenarioState and auth state to bridge model

**Mobile — Android Widget Wiring**
- AndroidManifest.xml: widget receiver registration for `DailyCardWidgetReceiver`
- AndroidManifest.xml: deep link intent-filter for `securitypulse://` URI scheme
- `security_pulse_widget_info.xml`: AppWidget metadata (180x110dp, 1hr update, resizable)
- `widget_loading.xml`: initial placeholder layout
- `build.gradle.kts`: core library desugaring enabled for flutter_local_notifications

**Mobile — iOS Widget Wiring**
- Info.plist: `CFBundleURLTypes` with `securitypulse` URL scheme
- Runner.entitlements and SecurityPulseWidget.entitlements: App Group `group.com.securitypulse.shared`
- SecurityPulseWidgetBundle.swift: WidgetKit entry point

**Mobile — Deep Link Handling**
- `deep_link_validator.dart`: whitelist-based path validation (T-05) — only `/today`, `/progress`, `/signin` accepted
- GoRouter redirect routes: `/today` → home, `/progress` → history, `/signin` → sign-in
- `DeepLinkPaths` constants in route_names.dart

**Mobile — Daily Notifications**
- `NotificationService` abstract interface (provider abstraction — no Firebase dependency)
- `LocalNotificationService` using `flutter_local_notifications`: daily repeating at 9:00 AM, static content only
- `MockNotificationService` for tests
- `NotificationPreferenceNotifier` (Riverpod): persists preference in flutter_secure_storage, handles permission requests
- Settings screen: notification toggle with SwitchListTile (replaced Phase 1 placeholder)
- 6 new localization keys for settings and notifications

**Testing**
- 35 new Flutter tests (185 total): DailyCardBridgeModel serialization, widget state mapper (all 7 states), deep link validation (whitelist, case-insensitive, query/fragment stripping), notification preference provider (enable/disable/permission denied), settings screen, widget sync provider
- All 106 backend tests pass (no regression)
- Debug APK builds successfully

**Security**
- T-05 mitigated: deep link paths validated via whitelist; unknown paths rejected; auth guard prevents unauthenticated access
- T-06 mitigated: only `DailyCardBridgeModel` written to shared storage; no tokens, answers, PII, or incident data
- T-07 mitigated: tokens never written to SharedPreferences or App Group UserDefaults
- T-15 mitigated: `expiresAt` field causes fallback to offline state; widget refreshes on timeline
- Notification content is static ("Security Pulse" / "Your daily security challenge is ready") — no sensitive data, lock-screen safe

### Added — Phase 4: Incident Reporting

**Backend**
- IncidentReport ORM model with enums: ReportType (9 values), IncidentSeverity, IncidentStatus
- Alembic migration `0003` creating incident_reports table with indexes on reporter_id, report_type, status, created_at
- Pydantic schemas with credential pattern rejection (T-11): regex-based detection of passwords, MFA codes, API keys in descriptions; forbidden metadata key validation
- Incident service layer: DB-based rate limiting (max 10 reports per user per hour, T-14), user-scoped queries (T-02), idempotency key support
- Routing abstraction: `IncidentRouterBase` ABC with `LogOnlyIncidentRouter` default implementation (fire-and-forget after DB commit)
- API endpoints: POST /incidents (201/200/429), GET /incidents/mine (paginated), GET /incidents/{id} (user-scoped)
- 37 new backend tests (106 total): incident service unit tests, schema validation, endpoint integration tests, routing abstraction, rate limiting, idempotency

**Mobile**
- Incident domain layer: ReportType, IncidentSeverity, IncidentStatus, DeviceType, DataClassification enums; IncidentReport and IncidentReportSummary models with fromJson factories
- IncidentRepository abstract interface with mock and API implementations
- Riverpod providers: IncidentFormNotifier (AutoDispose) with sealed state hierarchy (editing/submitting/success/error), IncidentHistoryNotifier with sealed states
- Incident report screen: full form with report type selector, title, description, date/time picker, severity radio buttons, conditional fields (type-specific), credential warning banner, urgent guidance banner
- Receipt view: displays report ID (truncated), title, type, timestamp with navigation to dashboard or history
- Incident history screen: paginated list with type badges, severity indicators, status
- Incident detail screen: read-only report view with credential warning
- FAB on daily scenario screen for quick incident reporting access
- RateLimitFailure class and 429 HTTP status mapping
- ~35 new localization keys for all incident reporting strings
- 44 new Flutter tests (150 total): model JSON parsing, form provider state management, history provider, screen widget tests (credential warning, urgent guidance, loading, receipt)

**Security**
- T-02 implemented: all incident queries filter by `reporter_id == current_user.id`; GET /incidents/{id} returns 404 for other users' reports
- T-11 implemented: no credential fields in forms; credential warning banner always visible; backend regex rejects password/MFA/API key patterns in descriptions; forbidden metadata keys validated
- T-14 implemented: DB-based rate limiting (COUNT query with 1-hour window, max 10 reports)

### Added — Phase 3: Backend-Driven Daily Scenario Delivery

**Backend**
- ORM models: Scenario, AnswerOption, Assignment, Response, Campaign, AuditEvent (SQLAlchemy)
- Alembic migration `0002` creating all scenario-related tables
- Pydantic schemas with T-03 enforcement: `AnswerOptionForEmployee` (pre-submission, no `is_correct`) and `AnswerOptionWithResult` (post-submission, includes `is_correct` + explanation)
- Scenario service layer with security enforcement: user-scoped queries (T-02), answer exposure prevention (T-03), duplicate response prevention (T-04)
- API endpoints: GET /scenarios/today, GET /scenarios/{id}, POST /scenarios/{id}/responses, GET /scenarios/{id}/result, GET /me/history, GET /me/progress
- Seed data: 5 published scenarios with answer options and assignments, loaded automatically in dev mode
- UniqueConstraint on `(user_id, scenario_id)` + `idempotency_key` column on Response for safe retries (T-04)
- 41 new backend tests (69 total): scenario service, API endpoints, authorization matrix, idempotency, seed verification

**Mobile**
- `ApiScenarioRepository` (Dio-based) for backend scenario API integration
- History screen with loading, empty, error, and data states
- Progress provider for streak and accuracy display
- `ResponseRecord` and `UserProgress` models with `fromJson` factories
- 21 new Flutter tests (106 total): API repository, history screen, progress provider, model serialization

**Security**
- T-02 implemented: all queries filter by authenticated `user_id`; service layer enforces user assignment on response submission
- T-03 implemented: separate Pydantic schemas structurally prevent `is_correct` leakage before submission
- T-04 implemented: database UniqueConstraint + idempotency_key prevent duplicate responses

### Added — Phase 2: Authentication and Authorization

**Backend**
- User ORM model with roles (employee, content_admin, security_admin) and status (active, inactive)
- Alembic migration for users table with unique index on identity_provider_subject
- Auth service with strategy pattern: OIDCAuthProvider (JWKS + JWT validation) and MockAuthProvider (dev only)
- FastAPI auth dependencies: get_current_user (Bearer token extraction + validation) and require_role (RBAC)
- Auth endpoints: GET /api/v1/auth/me (user profile), POST /api/v1/auth/logout (204 stateless)
- Auth schemas: TokenPayload and UserResponse (Pydantic)
- Structured audit logging for auth events via structlog (never logs token values)
- 28 backend tests (integration + unit) for auth endpoints, auth service, RBAC, and provider factory

**Mobile**
- Auth domain layer: User model, UserRole enum, AuthTokens value object, AuthRepository interface
- SecureTokenStorage wrapping flutter_secure_storage (Keychain on iOS, EncryptedSharedPreferences on Android)
- MockAuthRepository for local development (no IdP required)
- OidcAuthRepository using flutter_appauth for Authorization Code Flow with PKCE
- Auth presentation: sealed AuthState hierarchy, AuthNotifier (Riverpod), auth provider
- Dio HTTP client with AuthInterceptor (Bearer token attachment, 401 session expiry handling)
- GoRouter auth guard with redirect logic (unauthenticated → sign-in, authenticated → home)
- SecurityPulseApp converted to ConsumerStatefulWidget with refreshListenable for auth state changes
- SignInScreen wired to auth provider with loading/error states
- Auth localization keys in ARB files
- 33 new mobile tests (auth provider, sign-in screen, mock repository, router guards)

### Added — Phase 1: Daily Security Challenge
- Monorepo structure with Flutter mobile app, FastAPI backend, Next.js admin portal, and background worker
- Documentation: README, PRODUCT_SPEC, ARCHITECTURE, SECURITY, THREAT_MODEL, TEST_STRATEGY, RUNBOOK, CONTRIBUTING, CLAUDE, AGENTS
- OpenAPI 3.1 contract in packages/api-contract/openapi.yaml
- Design token definitions in packages/design-tokens/tokens.json
- Docker Compose for local development (PostgreSQL, Redis, API)
- GitHub Actions CI: Flutter, backend, admin portal
- Flutter shell app with loading, empty, error, offline, and unauthorized states
- Localization scaffold (ARB files)
- GoRouter with deep link configuration
- FastAPI health endpoints
- Next.js admin portal shell with TypeScript strict mode
- Environment variable template (.env.example)

---

## [0.0.1] — Phase 1 Foundation

Initial repository structure and project scaffold. No product features implemented.
