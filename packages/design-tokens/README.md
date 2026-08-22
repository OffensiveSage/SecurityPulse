# Design Tokens

Shared design tokens for Security Pulse.

These tokens are the single source of truth for colors, typography, spacing,
and other visual properties across the Flutter app, Next.js admin portal,
and native widgets.

## File

`tokens.json` — W3C Design Tokens Community Group format.

## Usage

### Flutter
Import from `lib/core/theme/app_colors.dart` and `lib/core/theme/app_typography.dart`.
These Dart files mirror the token values. When tokens change, update both the
JSON file and the Dart constants in the same PR.

### Next.js
The token values are referenced in `tailwind.config.ts`. Update that file when tokens change.

### Native widgets
The Swift and Kotlin widget files reference color values directly using the hex
values from this file. Keep them in sync when tokens change.

## Governance note

Brand colors in this file are **placeholders** pending brand confirmation
(governance decision — see `ARCHITECTURE.md § Governance decisions`).
Do not use these colors in external-facing materials until approved.
