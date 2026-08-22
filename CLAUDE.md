# Claude Code Project Instructions

You are primarily responsible for the Flutter mobile app, native widget UI (SwiftUI/WidgetKit for iOS, Kotlin/Jetpack Glance for Android), and the Next.js admin portal.

---

## Before editing anything

1. Read `PRODUCT_SPEC.md`, `ARCHITECTURE.md`, `SECURITY.md`, `API_CONTRACT.md`, `TEST_STRATEGY.md`, and all ADRs in `docs/adr/`.
2. Inspect existing code patterns before creating new abstractions.
3. State the files you intend to change before making changes.
4. Do not change the API contract without an approved ADR and a matching backend PR.
5. Do not begin Phase 2+ work until Phase 1 is approved.

---

## Rules

### Flutter
- Null safety must remain enabled. Never use `!` without a comment explaining why it is safe.
- Use design tokens from `packages/design-tokens/`. Do not hardcode repeated colors, spacing, or typography.
- Every screen must have loading, empty, error, offline, and unauthorized states.
- All user-visible strings must be localization keys in the ARB files. Never hardcode a string that a user will see.
- Meet WCAG 2.2 AA: provide Semantics labels on all interactive widgets, support dynamic text sizes, support screen readers.
- Never store tokens in plain SharedPreferences. Use `flutter_secure_storage`.
- The widget bridge must only write the minimal `DailyCardModel` to shared storage. No auth tokens, no answer correctness, no incident data, no full user identifiers.
- Add or update tests for every behavior change. Widget tests for every screen state. Unit tests for every use case and state change.
- Run `flutter analyze`, `dart format --set-exit-if-changed .`, and `flutter test` before marking work complete.

### Next.js admin portal
- Use strict TypeScript. No `any` without an explanatory comment.
- All user-visible strings must use the localization system.
- Meet WCAG 2.2 AA.
- Run `npm run type-check`, `npm run lint`, and `npm test` before marking work complete.

### General
- Provide a concise change summary and list known limitations after completing work.
- Do not add features, refactoring, or cleanup beyond what is requested.
- Do not merge your own PR. Human review is required.
