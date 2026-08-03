# Security

**Security Pulse — Security Requirements and Controls**  
Version: 1.0 | Status: Draft

---

## Authentication

- OIDC Authorization Code Flow with PKCE on mobile.
- Short-lived access tokens (target: 15 minutes; governance decision required).
- Refresh tokens stored in `flutter_secure_storage` (Keychain / EncryptedSharedPreferences).
- Server validates every token on every request. No client-trusted role checks.
- Separate RBAC roles: `employee`, `author`, `reviewer`, `approver`, `soc_analyst`, `platform_admin`.
- Deny by default: every protected endpoint returns `403` unless an explicit allow rule matches.
- Reauthentication required for high-risk admin actions (configurable).

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
