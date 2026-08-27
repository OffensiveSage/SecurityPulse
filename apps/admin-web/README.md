# Security Pulse admin portal

The Next.js administration portal for Security Pulse. Security-awareness and GRC teams use it to manage scenarios and campaigns, review aggregate analytics, prepare reports, and inspect administrative audit events.

The portal is pre-pilot software. It is not a production deployment and must not be used to make unsupported governance or personnel decisions.

## Requirements

- Node.js **20+**
- npm (the committed `package-lock.json` is the supported dependency lockfile)
- A local Security Pulse API when exercising live data

## Run locally

From this directory:

```bash
npm ci
npm run dev
```

Open [http://localhost:3000](http://localhost:3000). To run the backend locally, start the repository's Docker Compose stack from the repository root:

```bash
docker compose up -d
```

Confirm the API is available at `http://localhost:8000/health`.

## Development configuration

The portal uses these optional public environment variables:

| Variable | Default | Purpose |
|---|---|---|
| `NEXT_PUBLIC_API_BASE_URL` | `http://localhost:8000/api/v1` | Base URL for the Security Pulse API |
| `NEXT_PUBLIC_DEFAULT_ACCESS_TOKEN` | `mock-security_admin` | Local-development token sent when no per-request token is supplied |

The default token works only with a local API configured for mock authentication. It is not an identity solution and must never be set in a production deployment. Production access must use approved OIDC tokens and server-side authorization.

## Available workflows

- Dashboard with aggregate participation and accuracy summaries
- Scenario authoring and lifecycle management
- Campaign creation and eligibility calculation
- Suppression-aware analytics
- Reports and administrative audit-event views
- Employee management views

All API authorization is enforced by the backend. The UI must not be treated as a permission boundary, and aggregate views must preserve minimum-group-size suppression.

## Quality checks

```bash
npm run type-check
npm run lint
npm test
npm run build
```

## Related documentation

- [Repository overview](../../README.md)
- [Architecture](../../ARCHITECTURE.md)
- [API contract](../../API_CONTRACT.md)
- [Security controls](../../SECURITY.md)
- [Threat model](../../THREAT_MODEL.md)
- [Contributing guide](../../CONTRIBUTING.md)

## Security notes

Do not commit access tokens, secrets, or production URLs. The client adds a correlation ID to API requests and passes tokens per request; it does not persist them in the API module. Administrative actions and analytics access must remain audit logged by the API.
