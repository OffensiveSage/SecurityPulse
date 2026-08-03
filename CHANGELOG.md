# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Added
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
