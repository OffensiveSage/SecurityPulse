# Corporate Cybersecurity Awareness Widget
## Build and Handoff Specification

**Working name:** Security Pulse  
**Document version:** 1.1 (2026-08-03)  
**Purpose:** Give any developer or AI coding agent enough information to understand, build, test, and maintain the product.

---

## 1. Product Summary

Security Pulse is a mobile-first corporate cybersecurity awareness application for iOS, iPadOS, and Android.

The product delivers short, role-based security scenarios that employees can complete in under one minute. A home-screen widget shows the daily question, progress, or an urgent security message. The full mobile app handles answers, explanations, streaks, reporting, notifications, and profile settings.

An administrative web portal allows the security-awareness or GRC team to create questions, schedule campaigns, review aggregated results, and manage rewards.

The product is designed as an awareness and reporting companion. It is not a replacement for annual compliance training, an enterprise SIEM, an incident-response platform, or a learning-management system.

---

## 2. Primary Users

### Employee
- Views the daily widget.
- Opens and answers a scenario.
- Receives a brief explanation.
- Reviews previous learning.
- Reports a suspicious email, message, call, login, QR code, or device event.
- Tracks personal completion and optional streaks.

### Security Awareness or GRC Administrator
- Creates and approves content.
- Assigns content by role, department, country, or campaign.
- Reviews participation and missed-topic trends.
- Creates rewards or drawings.
- Exports approved aggregate metrics.

### SOC or Service Desk Analyst
- Receives structured incident reports.
- Reviews basic user-submitted facts.
- Routes reports to the organization’s approved ticketing or incident process.

### Platform Administrator
- Configures identity, permissions, retention, integrations, and environments.
- Manages deployments and operational monitoring.

---

## 3. MVP Scope

Build only the following for Version 1:

1. Corporate single sign-on.
2. Employee profile with department and region claims.
3. Daily scenario feed.
4. Multiple-choice answer flow.
5. Immediate explanation after submission.
6. iOS/iPadOS home-screen widget.
7. Android home-screen widget.
8. Push notification for an assigned question.
9. Simple incident-reporting form.
10. Employee completion history.
11. Admin content-management portal.
12. Aggregated analytics.
13. Basic quarterly prize-drawing eligibility.
14. Audit log for administrative actions.

Do not place these in Version 1:

- Live SIEM log ingestion.
- Automated incident classification using sensitive production data.
- Public employee leaderboards.
- AI-generated questions published without human approval.
- Cash-equivalent rewards without HR, Legal, Tax, and Ethics approval.
- Full LMS replacement.
- Direct access to corporate mailboxes.
- Collection of passwords, MFA codes, email bodies, or unnecessary device data.

---

## 4. Recommended Technology Stack

### Mobile application
- **Flutter and Dart**
- One shared application codebase for iOS, iPadOS, and Android.
- Native platform integrations where required.

### iOS and iPadOS widget
- **Swift + SwiftUI + WidgetKit**
- Shared App Group storage for limited widget-safe data.
- Deep link into the Flutter application.
- The widget extension lives inside the Flutter app's iOS runner project (`apps/mobile/ios/`); it is native code but not a separate app.

### Android widget
- **Kotlin + Jetpack Glance**
- Deep link into the Flutter application.
- WorkManager or approved periodic update mechanism when required.

### Admin portal
- **Next.js + TypeScript**
- Responsive internal web application.
- Component library: Material UI or organization-approved equivalent.

### Backend API
- **Python + FastAPI**
- REST API with an OpenAPI contract.
- SQLAlchemy 2.x and Alembic migrations.
- Pydantic request and response schemas.

### Database and supporting services
- PostgreSQL.
- Redis for short-lived caching and rate limiting.
- Object storage only for approved attachments.
- Background worker for notifications, exports, and scheduled campaign publishing.

### Enterprise identity
- OpenID Connect or OAuth 2.0 through the organization’s identity provider.
- Microsoft Entra ID is a suitable implementation option when approved.
- Mobile Authorization Code Flow with PKCE.
- Role and department information should come from trusted identity claims or an approved directory synchronization process.

### Deployment
Prefer the organization’s approved cloud and mobile-device-management platform. A reasonable reference implementation is:

- Containers for API and worker.
- Managed PostgreSQL.
- Managed secrets vault.
- Private networking where required.
- CI/CD through GitHub Actions or the approved enterprise pipeline.
- iOS private distribution through MDM or Apple Business Manager.
- Android managed distribution through MDM or Managed Google Play.

Do not assume a specific corporate platform until architecture and security teams confirm it.

---

## 5. High-Level Architecture

```text
+----------------------+          +----------------------+
| Flutter Mobile App   |          | Admin Web Portal     |
| iOS / iPad / Android |          | Next.js / TypeScript |
+----------+-----------+          +----------+-----------+
           |                                 |
           | HTTPS + OIDC access token       |
           +----------------+----------------+
                            |
                   +--------v---------+
                   | FastAPI Backend  |
                   | REST / OpenAPI   |
                   +---+----+----+----+
                       |    |    |
          +------------+    |    +------------------+
          |                 |                       |
+---------v--------+ +------v------+       +--------v---------+
| PostgreSQL       | | Redis       |       | Notification     |
| Core data        | | Cache/rate  |       | worker           |
+------------------+ +-------------+       +------------------+

iOS Widget:
WidgetKit -> reads a minimal cached daily-card model -> deep-links to app.

Android Widget:
Jetpack Glance -> reads a minimal cached daily-card model -> deep-links to app.
```

The widgets must never contain authentication tokens, detailed user history, sensitive incident information, or confidential corporate data.

---

## 6. Core User Flows

### 6.1 First sign-in
1. Employee launches the app.
2. App redirects to corporate SSO.
3. Backend validates the identity token.
4. Backend creates or updates the minimum employee profile.
5. Employee sees the assigned daily scenario.
6. App stores only the minimum widget-safe scenario summary locally.

### 6.2 Daily question
1. Widget shows the question title and “Answer now.”
2. Employee taps the widget.
3. Deep link opens the relevant scenario.
4. Employee selects one answer.
5. Backend records the response once.
6. App shows correct answer and explanation.
7. Progress and eligibility are updated.
8. Widget refreshes to show “Completed.”

### 6.3 Incident reporting
1. Employee taps “Report suspicious activity.”
2. Selects type: email, Teams/chat, SMS, call, login, QR code, lost device, or other.
3. Answers structured questions:
   - What happened?
   - Did you click?
   - Did you enter credentials?
   - Did you download or open a file?
   - When did it happen?
4. App displays an emergency instruction when credentials may be compromised.
5. Backend creates a report and routes it to an approved downstream process.
6. Employee receives a reference number.

The app must explicitly state: “Never enter your password or MFA code in this form.”

### 6.4 Administrative publishing
1. Author creates a draft scenario.
2. Reviewer checks accuracy, policy alignment, accessibility, and localization.
3. Approver publishes or schedules it.
4. Scheduler assigns it to eligible audiences.
5. Audit log records each action.

### 6.5 Rewards
1. Administrator creates a campaign eligibility rule.
2. System calculates eligible participants.
3. Administrator exports or performs an auditable random drawing.
4. Final winner approval remains outside the app until HR, Legal, Tax, Ethics, and regional requirements are satisfied.

---

## 7. Data Model

### User
- id: UUID
- identity_provider_subject: string
- employee_hash_or_id: string
- display_name: optional
- email: optional, encrypted or directory-resolved
- department: optional
- region: optional
- role_profile: enum
- status: active/inactive
- created_at
- updated_at

### Scenario
- id: UUID
- title
- prompt
- category
- difficulty
- role_profiles
- regions
- status: draft/review/approved/published/retired
- explanation
- policy_reference
- created_by
- approved_by
- publish_at
- expire_at
- version
- created_at
- updated_at

### AnswerOption
- id
- scenario_id
- text
- is_correct
- explanation_override: optional
- display_order

`is_correct` and `explanation_override` must be stripped from any scenario response served to an employee before submission. Correctness is only revealed by the result endpoint after a recorded response.

### Assignment
- id
- scenario_id
- audience_rule
- available_from
- due_at
- campaign_id

### Response
- id
- user_id
- scenario_id
- selected_option_id
- is_correct
- submitted_at
- response_time_ms: optional
- source: app/widget/deep_link

Unique constraint on (user_id, scenario_id) to enforce single-submission idempotency at the database level.

### IncidentReport
- id
- user_id
- event_type
- occurred_at
- clicked
- credentials_entered
- file_opened
- short_description
- attachment_reference: optional
- status
- external_ticket_reference: optional
- created_at
- updated_at

### Campaign
- id
- name
- start_at
- end_at
- eligibility_rule
- reward_description
- status

### AuditEvent
- id
- actor_id
- action
- target_type
- target_id
- before_summary
- after_summary
- timestamp
- correlation_id

---

## 8. API Contract

Use `/api/v1`.

### Authentication
- `GET /auth/me`
- `POST /auth/logout`

### Employee
- `GET /me/profile`
- `PATCH /me/preferences`
- `GET /me/progress`
- `GET /me/history`

### Scenarios
- `GET /scenarios/today`
- `GET /scenarios/{scenario_id}`
- `POST /scenarios/{scenario_id}/responses`
- `GET /scenarios/{scenario_id}/result`

### Widget
- `GET /widget/daily-card`

Widgets never hold authentication tokens or long-lived secrets. The daily-card model is fetched by the app and written to shared storage; the widget itself makes no authenticated calls.

### Incident reports
- `POST /incident-reports`
- `GET /incident-reports/{report_id}/receipt`

### Admin
- `GET /admin/scenarios`
- `POST /admin/scenarios`
- `PATCH /admin/scenarios/{scenario_id}`
- `POST /admin/scenarios/{scenario_id}/submit-review`
- `POST /admin/scenarios/{scenario_id}/approve`
- `POST /admin/scenarios/{scenario_id}/publish`
- `GET /admin/analytics/summary`
- `GET /admin/campaigns`
- `POST /admin/campaigns`
- `POST /admin/campaigns/{campaign_id}/calculate-eligibility`
- `GET /admin/audit-events`

### API rules
- Idempotency key for response submission and incident creation.
- Pagination for list endpoints.
- Server-side authorization on every endpoint.
- No client-trusted role checks.
- Standard error envelope.
- Correlation ID in every request and response.
- OpenAPI generated and committed as a versioned artifact.
- Breaking changes require a new API version.

---

## 9. Security and Privacy Requirements

### Authentication and authorization
- OIDC Authorization Code Flow with PKCE for mobile.
- Short-lived access tokens.
- Role-based access control for employee, author, reviewer, approver, SOC analyst, and platform administrator.
- Separate administrative permissions from content-authoring permissions.
- Reauthentication for high-risk administrative actions where appropriate.

### Data minimization
- Collect only data required for awareness, assignment, reporting, and approved analytics.
- Prefer department-level analytics.
- Do not store message bodies by default.
- Do not collect passwords, MFA codes, contact lists, microphone data, photos, or device location.
- Attachments must be optional and governed by retention and malware-scanning rules.

### Application security
- TLS everywhere.
- Encryption at rest.
- Secrets only in an approved secrets manager.
- Input validation and output encoding.
- Parameterized database access.
- CSRF protection for the admin portal.
- Rate limiting.
- Secure headers.
- Dependency scanning.
- Static analysis.
- Container scanning.
- Mobile secure-storage APIs for tokens.
- Rooted or jailbroken device handling according to corporate policy.
- No sensitive information in logs or crash reports.

### Auditability
Record:
- Sign-in and administrative authorization failures.
- Content creation, review, approval, publishing, and retirement.
- Campaign rule changes.
- Analytics exports.
- Integration configuration changes.
- Incident status changes.

Do not log:
- Access tokens.
- Passwords.
- MFA codes.
- Complete confidential messages.
- Sensitive attachment contents.

### Retention
Retention must be configurable and approved by Privacy, Legal, HR, Security, and regional stakeholders. Separate:
- Awareness response retention.
- Incident-report retention.
- Administrative audit retention.
- Operational log retention.

---

## 10. User Experience Requirements

### General
- One daily interaction should take 30–60 seconds.
- Maximum four answer options.
- Explanation should be 40–100 words.
- Reading level should suit a broad global workforce.
- Avoid shame, fear, and trick wording.
- Include a clear recommended action.
- Support accessibility and screen readers.
- Support dynamic text sizes.
- Design for light and dark mode.
- Localization-ready from the first commit.

### Widget
The widget should show only:
- Product name or icon.
- Scenario title or short question.
- Completion state.
- One primary action.
- Optional streak or weekly progress.

Do not answer a complex question entirely inside the widget during the MVP. Deep-link to the full app to preserve accessibility, analytics consistency, and explanation quality.

### Admin portal
- Draft autosave.
- Preview for mobile and widget.
- Four-eyes approval workflow.
- Search and filtering.
- Version history.
- Localization status.
- Accessible charts and downloadable aggregate reports.

---

## 11. Suggested Repository Layout

```text
security-pulse/
├── README.md
├── PRODUCT_SPEC.md
├── ARCHITECTURE.md
├── SECURITY.md
├── PRIVACY.md
├── THREAT_MODEL.md
├── API_CONTRACT.md
├── TEST_STRATEGY.md
├── RUNBOOK.md
├── CONTRIBUTING.md
├── AGENTS.md
├── CLAUDE.md
├── .env.example
├── docker-compose.yml
├── apps/
│   ├── mobile/
│   │   ├── lib/
│   │   ├── test/
│   │   ├── integration_test/
│   │   ├── ios/
│   │   │   └── SecurityPulseWidget/
│   │   └── android/
│   │       └── app/src/main/kotlin/.../widget/
│   └── admin-web/
│       ├── src/
│       ├── public/
│       └── tests/
├── services/
│   ├── api/
│   │   ├── app/
│   │   │   ├── api/
│   │   │   ├── core/
│   │   │   ├── models/
│   │   │   ├── schemas/
│   │   │   ├── services/
│   │   │   └── main.py
│   │   ├── tests/
│   │   ├── alembic/
│   │   └── pyproject.toml
│   └── worker/
├── packages/
│   ├── api-contract/
│   ├── design-tokens/
│   └── test-fixtures/
├── infrastructure/
│   ├── modules/
│   ├── environments/
│   │   ├── dev/
│   │   ├── test/
│   │   └── prod/
│   └── policies/
├── docs/
│   ├── adr/
│   ├── diagrams/
│   ├── content-guidelines/
│   └── operations/
└── .github/
    └── workflows/
```

---

## 12. Division of Work Between Claude Code and Codex

The separation below is a workflow recommendation, not a technical limitation. Both agents should review each other’s work. If only one agent is used, it takes on both roles, but the cross-review checklists in this section must still be executed as an explicit self-review step before merge.

### Claude Code: primary responsibility
- Flutter mobile interface.
- Next.js admin interface.
- Design system and reusable components.
- Navigation and state handling.
- Accessibility.
- Responsive layouts.
- Localization framework.
- Widget visual implementation with native bridge code.
- Golden tests and UI tests.
- Frontend documentation.
- API client generated from the approved OpenAPI contract.

### Codex: primary responsibility
- FastAPI backend.
- PostgreSQL schema and migrations.
- Authentication middleware.
- Authorization policy.
- Scenario assignment engine.
- Response and progress logic.
- Incident-report workflow.
- Notification worker.
- Audit logging.
- Tests, fixtures, security checks, and API documentation.
- Docker and local development environment.
- CI/CD, infrastructure skeleton, and operational runbook.

### Cross-review responsibilities
Claude Code reviews:
- API usability from the mobile and admin perspective.
- Error models.
- Missing loading, empty, offline, and permission states.
- Accessibility and localization implications.

Codex reviews:
- Authentication and authorization.
- Data leakage.
- Input validation.
- Concurrency and idempotency.
- Database migrations.
- Logging and operational failure handling.
- Dependency and deployment risk.

No agent should merge its own pull request without human review.

---

## 13. Required Agent Instruction Files

### `CLAUDE.md`

```markdown
# Claude Code Project Instructions

You are primarily responsible for the Flutter mobile app, native widget UI,
and Next.js admin portal.

Before editing:
1. Read PRODUCT_SPEC.md, ARCHITECTURE.md, SECURITY.md, API_CONTRACT.md,
   TEST_STRATEGY.md, and relevant ADRs.
2. Inspect existing patterns before creating new abstractions.
3. State the files you intend to change.
4. Do not change the API contract without an approved ADR and matching backend PR.

Rules:
- Use strict TypeScript.
- Keep Flutter null safety enabled.
- Use design tokens; do not hardcode repeated styling.
- Every screen needs loading, empty, error, offline, and unauthorized behavior.
- All user-visible strings must be localization keys.
- Meet WCAG 2.2 AA where applicable.
- Never store tokens in plain shared preferences.
- Widgets receive only a minimal non-sensitive cached view model.
- Add or update tests for every behavior change.
- Run formatters, linters, type checks, and relevant tests before completion.
- Provide a concise change summary and known limitations.
```

### `AGENTS.md`

```markdown
# Codex Project Instructions

You are primarily responsible for the FastAPI backend, PostgreSQL persistence,
authorization, jobs, tests, infrastructure, and operational documentation.

Before editing:
1. Read PRODUCT_SPEC.md, ARCHITECTURE.md, SECURITY.md, THREAT_MODEL.md,
   API_CONTRACT.md, TEST_STRATEGY.md, and relevant ADRs.
2. Trace the existing request and data flow.
3. State assumptions and files to change.
4. Keep backward compatibility unless an approved API version change exists.

Rules:
- Use typed Python and strict static analysis.
- Validate every external input with Pydantic.
- Authorize every protected action server-side.
- Use migrations for every database change.
- Make response submission and incident creation idempotent.
- Never log tokens, credentials, confidential message bodies, or attachment data.
- Add unit, integration, authorization, and negative tests.
- Update OpenAPI, runbooks, and threat model when behavior changes.
- Run formatters, linters, type checks, tests, and security scans.
- Provide a concise change summary, migration notes, rollback notes, and risks.
```

---

## 14. Build Phases and Agent Prompts

### Phase 0: Product and architecture foundation

**Human tasks**
- Confirm sponsor and business owner.
- Confirm whether this is a student prototype, internal pilot, or production proposal.
- Confirm approved cloud, identity provider, MDM, ticketing, and analytics tools.
- Obtain security, privacy, HR, legal, accessibility, and branding contacts.
- Decide pilot audience and success criteria.

**Codex prompt**
```text
Read PRODUCT_SPEC.md. Create ARCHITECTURE.md, SECURITY.md, THREAT_MODEL.md,
API_CONTRACT.md, TEST_STRATEGY.md, RUNBOOK.md, and ADR-0001 for the proposed
stack. Do not implement production code yet. Identify all unconfirmed
enterprise dependencies as explicit decisions, not assumptions. Include data
flows, trust boundaries, abuse cases, retention questions, and rollback
requirements. Finish with an architecture review checklist.
```

**Claude Code prompt**
```text
Read PRODUCT_SPEC.md and the draft architecture documents. Create a UX
information architecture, screen inventory, user-flow document, design-token
proposal, accessibility checklist, widget-size matrix, and low-fidelity
component plan. Do not build polished UI yet. Mark every point that depends on
branding, policy wording, localization, or enterprise identity.
```

**Exit criteria**
- Architecture approved.
- Threat model reviewed.
- API contract drafted.
- MVP scope frozen.
- Enterprise unknowns documented.

---

### Phase 1: Repository and local development

**Codex prompt**
```text
Initialize the monorepo structure defined in PRODUCT_SPEC.md. Create the
FastAPI service, PostgreSQL development database, Alembic, Redis, worker
skeleton, Docker Compose, environment templates, health endpoints, structured
logging, correlation IDs, and CI checks. Add a local mock identity provider
mode that cannot be enabled in production. Add tests proving production rejects
mock authentication. Update README.md with exact setup and troubleshooting.
```

**Claude Code prompt**
```text
Initialize the Flutter app and Next.js admin portal in the existing monorepo.
Create shared design tokens, routing, environment handling, localization
scaffolding, linting, formatting, component tests, and CI commands. Implement
only shell screens with loading, empty, error, offline, and unauthorized states.
Do not invent backend fields; use the committed API contract.
```

**Exit criteria**
- One-command local startup.
- CI passes.
- Mock auth restricted to development.
- Empty mobile and admin shells run.

---

### Phase 2: Authentication and authorization

**Codex prompt**
```text
Implement OIDC-compatible authentication interfaces and a development mock.
Create user provisioning from trusted claims, RBAC policies, protected route
dependencies, authorization tests, and audit events. Support employee, author,
reviewer, approver, SOC analyst, and platform administrator. Deny by default.
Document token validation, claim mapping, clock skew, key rotation, logout, and
failure behavior. Do not store raw access tokens.
```

**Claude Code prompt**
```text
Implement the Flutter and Next.js authentication flows against the approved
contract. Create sign-in, sign-out, expired-session, denied-access, and
recovery states. Use platform-secure token storage on mobile. Do not store
tokens in widget storage. Add tests for deep links received before, during, and
after authentication.
```

**Exit criteria**
- Unauthorized requests are denied.
- Role escalation tests fail safely.
- Token expiry and logout work.
- Deep links resume after authentication.

---

### Phase 3: Scenario authoring and delivery

**Codex prompt**
```text
Implement Scenario, AnswerOption, Assignment, Response, Campaign, and
AuditEvent persistence and APIs. Add draft-review-approve-publish state
transitions, audience rules, scheduling, versioning, and idempotent response
submission. Ensure correct answers are not exposed before submission. Add unit,
integration, authorization, concurrency, and negative tests. Generate and
commit the OpenAPI artifact.
```

**Claude Code prompt**
```text
Implement the employee daily-scenario flow and the admin scenario-authoring
workflow. Use generated API clients. Include accessible answer controls,
confirmation, explanation, history, draft autosave, preview, validation,
version display, and approval-state UI. Add component, navigation, and
end-to-end tests. Never infer the correct answer before the backend result.
```

**Exit criteria**
- Content requires approval before publication.
- Correct answers cannot be fetched early.
- Duplicate responses do not create duplicate progress.
- Admin actions are audited.

---

### Phase 4: Native widgets

**Claude Code prompt**
```text
Implement the iOS/iPadOS widget using SwiftUI and WidgetKit and the Android
widget using Kotlin and Jetpack Glance. The Flutter app must write only a
minimal widget-safe daily-card model to platform-approved shared storage.
Include completed, available, offline, signed-out, and no-assignment states.
Each widget action deep-links to the correct Flutter route. Do not store tokens,
incident data, answer correctness, employee identifiers, or confidential text
in widget storage. Add native tests where possible and document simulator and
device testing.
```

**Codex review prompt**
```text
Review the widget implementation for data exposure, deep-link tampering,
authorization bypass, stale-state behavior, replay risk, and logging issues.
Do not redesign the UI. Produce findings by severity and implement approved
backend or contract fixes with tests.
```

**Exit criteria**
- Widgets operate on supported iOS/iPadOS and Android devices.
- No sensitive data is present in shared widget storage.
- Tampered deep links do not bypass server authorization.
- Stale widget states recover safely.

---

### Phase 5: Incident reporting

**Codex prompt**
```text
Implement structured incident-report creation with idempotency, validation,
safe status tracking, audit events, configurable routing adapter, and receipt
numbers. Do not accept passwords or MFA codes. Add size and type controls for
optional attachments but keep attachments disabled by default. Add an
integration interface for an approved ticketing platform without hardcoding a
vendor. Include emergency response text as server-managed policy content.
```

**Claude Code prompt**
```text
Implement the incident-report wizard for mobile and the triage view for
authorized analysts. Clearly warn users not to submit passwords or MFA codes.
Show conditional urgent guidance when credentials were entered or a device was
lost. Include accessible forms, save-and-resume rules, confirmation receipt,
and failure recovery. Do not request mailbox access, contacts, microphone,
location, or broad photo-library permission.
```

**Exit criteria**
- No credential fields exist.
- Failed downstream routing does not lose the report.
- User receives a reference number.
- Only authorized analysts can view reports.

---

### Phase 6: Analytics and rewards

**Codex prompt**
```text
Implement privacy-preserving aggregate analytics and campaign eligibility.
Enforce minimum group-size suppression for department or regional breakdowns.
Do not create a public individual leaderboard. Add an auditable random-drawing
export that includes only approved eligibility identifiers. Make reward
configuration display a mandatory governance disclaimer. Test small-group
suppression, authorization, export auditing, and deterministic eligibility.
```

**Claude Code prompt**
```text
Build accessible admin analytics for participation, completion, accuracy by
topic, and reporting trends. Show suppression messages instead of small-group
data. Build the campaign and eligibility interface, but make final winner
approval an external governed step. Avoid manipulative gamification and public
employee ranking.
```

**Exit criteria**
- Small teams cannot be inferred from dashboards.
- Analytics exports are audited.
- Reward eligibility is explainable.
- Final award remains governed by corporate approval.

---

### Phase 7: Production hardening and pilot

**Codex prompt**
```text
Perform a production-readiness review. Add rate limiting, secure headers,
database backup and restore documentation, health and readiness probes,
observability, alerting rules, dependency and container scans, migration
rollback steps, load tests, failure-injection tests, and a pilot runbook.
Produce a release checklist and a list of unresolved risks. Do not mark the
system production-ready unless every required control has evidence.
```

**Claude Code prompt**
```text
Perform mobile and admin production hardening. Validate accessibility,
localization, offline behavior, notification permissions, deep links, widget
refresh, tablet layouts, privacy disclosures, crash behavior, and supported OS
versions. Create a device-test matrix and pilot feedback form. Record
screenshots or test evidence without exposing corporate data.
```

**Exit criteria**
- Security review completed.
- Privacy and accessibility review completed.
- Restore test completed.
- Pilot support and rollback plan approved.
- Test evidence attached to the release.

---

## 15. Testing Strategy

### Backend
- Unit tests for assignment and eligibility logic.
- API integration tests.
- Database migration tests.
- Authorization matrix tests.
- Negative security tests.
- Idempotency and concurrency tests.
- Scheduler and worker tests.
- Contract tests against OpenAPI.
- Load tests for daily notification spikes.
- Backup and restore test.

### Flutter mobile
- Unit tests for state and mapping.
- Widget tests for every screen state.
- Integration tests for sign-in, scenario, result, history, and incident report.
- Deep-link tests.
- Offline and retry tests.
- Secure-storage tests.
- Accessibility tests.
- Localization overflow tests.
- Physical-device tests.

### Native widgets
- Small, medium, and large sizes where supported.
- Signed-in and signed-out.
- Assigned and no assignment.
- Completed and incomplete.
- Network unavailable.
- Stale cached content.
- Deep-link tampering.
- Device reboot.
- App upgraded or removed.

### Admin portal
- Component tests.
- Role-based route tests.
- Draft, review, approve, publish workflow.
- Autosave and conflict behavior.
- Analytics suppression.
- Export authorization.
- Keyboard-only and screen-reader testing.

### Security gates
- Secret scanning.
- Dependency scanning.
- Static application security testing.
- Infrastructure policy checks.
- Container scanning.
- Mobile binary review before pilot.
- Manual authorization review.
- Threat-model update for significant changes.

---

## 16. Definition of Done

A feature is complete only when:

- Acceptance criteria are met.
- Code is reviewed by a human.
- Tests are added and passing.
- Authorization is tested.
- Failure states are implemented.
- Accessibility is checked.
- User-visible text is localization-ready.
- API and architecture documentation are updated.
- Threat model is updated when data flow changes.
- Logs contain no sensitive data.
- Migration and rollback instructions exist when needed.
- Screenshots or test evidence are attached.
- Product owner accepts the behavior.

---

## 17. Pilot Success Metrics

Suggested eight-week pilot metrics:

- Weekly active participation.
- Percentage completing at least 80% of assigned questions.
- Change in accuracy between baseline and final assessment.
- Accuracy by topic.
- Increase in correctly reported suspicious events.
- Median time to complete a daily scenario.
- Notification opt-out rate.
- User-reported usefulness.
- False or duplicate incident submissions.
- Support tickets and app failures.
- Accessibility issues.
- No material privacy or security incidents caused by the pilot.

Avoid using raw completion scores as an employee-performance measure unless formally approved and communicated.

---

## 18. Governance Decisions Required Before Production

1. Product owner and funding owner.
2. Approved identity provider and claim source.
3. Approved cloud and database region.
4. Approved MDM and app-distribution route.
5. Approved ticketing or incident integration.
6. Data retention periods.
7. Countries and languages.
8. Works-council or employee-representative requirements.
9. Whether individual response data is visible to managers.
10. Minimum group size for analytics.
11. Reward approval, tax handling, and regional eligibility.
12. Attachment policy.
13. Supported OS versions.
14. Accessibility standard.
15. Incident emergency wording.
16. Operational support team and SLA.
17. Business continuity and disaster recovery requirements.

---

## 19. Recommended First Sprint

### Sprint goal
Demonstrate the complete daily-question experience without production integrations.

### Deliverables
- Local monorepo.
- Mock SSO.
- FastAPI API.
- PostgreSQL schema.
- Flutter sign-in shell.
- Daily question screen.
- Answer submission and explanation.
- One iOS widget prototype.
- One Android widget prototype.
- Minimal admin question creator.
- Automated tests.
- README with local setup.
- Architecture and threat-model review notes.

### Demo script
1. Sign in as a mock employee.
2. View the question from the widget.
3. Open the app through a deep link.
4. Answer incorrectly.
5. View the explanation.
6. See progress update.
7. Sign in as an author.
8. Create a draft scenario.
9. Sign in as an approver.
10. Approve and publish it.
11. Refresh the employee assignment.
12. Show audit history.

---

## 20. Final Handoff Checklist

A new developer should be able to answer all of these after reading the repository:

- What problem does the product solve?
- Who owns each part?
- What is included in the MVP?
- What is explicitly excluded?
- How does authentication work?
- What data is collected?
- Where is data stored?
- What can appear in a widget?
- How is content approved?
- How are incidents reported?
- How are analytics protected?
- How are rewards governed?
- How is the system run locally?
- How is it tested?
- How is it deployed?
- How is it monitored?
- How is it rolled back?
- What decisions are still unresolved?

If any answer is missing, update the documentation before handing the project to another person or coding agent.

---

## 21. Official Technical References

- OpenAI Codex documentation and Codex CLI documentation.
- Anthropic Claude Code overview, quickstart, permissions, and project-instruction documentation.
- Flutter official mobile and platform-integration documentation.
- Apple WidgetKit and TimelineProvider documentation.
- Android App Widgets and Jetpack Glance documentation.
- Organization-approved identity, MDM, privacy, and secure-development standards.

Always check the current official documentation before production implementation because agent tooling, mobile-platform APIs, and enterprise requirements can change.
