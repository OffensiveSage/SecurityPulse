# Product Specification

**Security Pulse — Product Specification**  
Version: 1.1 | Date: 2026-08-03

This document is the canonical product specification. It is derived from
`Security_Pulse_Build_Handoff.md` and maintained as the source of truth
for all subsequent development.

---

## Product summary

Security Pulse is a mobile-first corporate cybersecurity awareness application
for iOS, iPadOS, and Android.

The product delivers short, role-based security scenarios that employees can
complete in under one minute. A home-screen widget shows the daily question,
progress, or an urgent security message. The full mobile app handles answers,
explanations, streaks, reporting, notifications, and profile settings.

An administrative web portal allows the security-awareness or GRC team to
create questions, schedule campaigns, review aggregated results, and manage
rewards.

**This product is not a replacement for:** annual compliance training, an
enterprise SIEM, an incident-response platform, or a learning-management system.

---

## Primary users

| Role | Key actions |
|---|---|
| Employee | View widget, answer daily scenario, read explanation, report suspicious activity, track history |
| Security Awareness / GRC Admin | Author and approve content, assign campaigns, review analytics, manage rewards |
| SOC / Service Desk Analyst | Receive structured incident reports, route to ticketing |
| Platform Admin | Configure identity, permissions, retention, integrations, deployments |

---

## MVP scope (Version 1)

**Included:**
1. Corporate single sign-on (OIDC/PKCE)
2. Employee profile with department and region claims
3. Daily scenario feed
4. Multiple-choice answer flow (max 4 options)
5. Immediate explanation after submission
6. iOS/iPadOS home-screen widget (SwiftUI + WidgetKit)
7. Android home-screen widget (Kotlin + Jetpack Glance)
8. Push notification for assigned question
9. Simple incident-reporting form
10. Employee completion history
11. Admin content-management portal (Next.js)
12. Aggregated analytics (department-level, with group-size suppression)
13. Basic quarterly prize-drawing eligibility
14. Audit log for administrative actions

**Explicitly excluded from Version 1:**
- Live SIEM log ingestion
- Automated incident classification using sensitive production data
- Public employee leaderboards
- AI-generated questions published without human approval
- Cash-equivalent rewards without HR, Legal, Tax, and Ethics approval
- Full LMS replacement
- Direct access to corporate mailboxes
- Collection of passwords, MFA codes, contact lists, microphone, photos, or device location

---

## Technology stack

See `ARCHITECTURE.md` and `docs/adr/ADR-0001-tech-stack.md` for rationale.

| Component | Technology |
|---|---|
| Mobile app | Flutter + Dart |
| iOS/iPadOS widget | Swift + SwiftUI + WidgetKit |
| Android widget | Kotlin + Jetpack Glance |
| Admin portal | Next.js + TypeScript |
| Backend API | Python + FastAPI |
| Database | PostgreSQL 16 |
| Cache | Redis 7 |
| Authentication | OIDC / OAuth 2.0 + PKCE |

---

## Data model summary

Full data model is defined in `packages/api-contract/openapi.yaml`.

| Entity | Key fields |
|---|---|
| User | id, identity_provider_subject, department, region, role_profile, status |
| Scenario | id, title, prompt, category, difficulty, status (draft→review→approved→published→retired), explanation |
| AnswerOption | id, scenario_id, text, is_correct\*, explanation_override\* |
| Assignment | id, scenario_id, audience_rule, available_from, due_at |
| Response | id, user_id, scenario_id, selected_option_id, is_correct, submitted_at |
| IncidentReport | id, user_id, event_type, occurred_at, clicked, credentials_entered, file_opened, short_description |
| Campaign | id, name, start_at, end_at, eligibility_rule, status |
| AuditEvent | id, actor_id, action, target_type, target_id, before_summary, after_summary, timestamp |

\* `is_correct` and `explanation_override` are never served to employees before submission.

---

## Core user flows

Full flows are defined in `ARCHITECTURE.md`. Summary:

1. **First sign-in:** App → SSO redirect → token validation → profile creation → daily scenario
2. **Daily question:** Widget shows title → employee taps → deep link to app → answers → explanation → widget updates
3. **Incident report:** Employee taps report → selects type → structured questions → backend routes → reference number
4. **Content approval:** Author creates draft → reviewer checks → approver publishes → audit logged
5. **Rewards:** Admin creates eligibility rule → system calculates → admin exports → final approval is external

---

## Security requirements (summary)

Full security requirements are in `SECURITY.md` and `THREAT_MODEL.md`.

- OIDC PKCE on mobile; server-side session on admin portal
- Short-lived access tokens; tokens in flutter_secure_storage only
- No tokens in widget storage
- Deny by default; all role checks server-side
- No credential fields anywhere; explicit warning in incident form
- Aggregated analytics only; minimum group size suppressed

---

## Build phases

| Phase | Scope |
|---|---|
| 0 | Architecture and documentation foundation |
| 1 | Repository scaffold, local development (current) |
| 2 | Authentication and authorization |
| 3 | Scenario authoring and delivery |
| 4 | Native widgets |
| 5 | Incident reporting |
| 6 | Analytics and rewards |
| 7 | Production hardening and pilot |

---

## Governance decisions (17 open)

All listed in `ARCHITECTURE.md § Governance decisions`.
None are resolved. All must be resolved before production.

---

## Definition of done

A feature is complete only when all 12 criteria in `TEST_STRATEGY.md § Definition of done` are satisfied.
