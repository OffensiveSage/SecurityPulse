# Security Pulse mobile app

The Flutter client for Security Pulse. It provides the employee experience on iOS, iPadOS, and Android: a daily security challenge, answer feedback, history and progress, incident reporting, notification preferences, and a safe bridge to native home-screen widgets.

The application supports three onboarding contexts:

- **Work** — corporate sign-in and assigned daily challenges.
- **Personal** — guest access to security topic packs.
- **School** — class-code onboarding with student and teacher experiences.

## Requirements

- Flutter **3.27+** with Dart **3.6+**
- Xcode and CocoaPods for iOS/iPadOS development
- Android Studio and an Android SDK for Android development

Check the active toolchain with:

```bash
flutter --version
flutter doctor
```

## Run locally

From this directory:

```bash
flutter pub get
flutter run
```

Use `flutter devices` to list available simulators, emulators, and connected devices. On first launch, select Work, Personal, or School from the mode selector.

### Local development behavior

The app currently uses mock authentication and mock scenario data by default, so it can run without a local API or identity provider. The mock sign-in creates a test employee session stored with `flutter_secure_storage`; it is for development only.

API-backed and OIDC repository implementations are included, but connecting them requires approved environment-specific configuration and provider overrides. Do not point the app at a production identity provider or use mock authentication in production.

## Quality checks

Run these before opening a pull request:

```bash
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

To regenerate generated client and provider code after changing annotated sources:

```bash
dart run build_runner build
```

## Architecture

- **State:** Riverpod
- **Navigation:** GoRouter, with authentication guards and allowlisted deep links
- **Networking:** Dio and Retrofit-compatible API layer
- **Authentication:** OIDC Authorization Code with PKCE; tokens belong only in `flutter_secure_storage`
- **Localization:** English ARB sources in `lib/core/l10n/`
- **Native widgets:** MethodChannel bridge to iOS WidgetKit and Android Glance

The native-widget payload is deliberately limited to a scenario ID, title, display state, internal route, and expiry. It must never contain tokens, answer correctness, incident content, or other personal data.

## Key experiences

- Daily scenario lifecycle: loading, challenge introduction, answer selection, submission, and result
- History and progress views
- Incident reporting with credential warnings, input validation, and urgent guidance
- Notification preference and a static daily reminder
- Empty, error, offline, and unauthorized UI states
- Deep links limited to `/today`, `/progress`, and `/signin`

## Related documentation

- [Repository overview](../../README.md)
- [Architecture](../../ARCHITECTURE.md)
- [Security controls](../../SECURITY.md)
- [Threat model](../../THREAT_MODEL.md)
- [API contract](../../API_CONTRACT.md)
- [Test strategy](../../TEST_STRATEGY.md)

## Security notes

Never place access or refresh tokens in `SharedPreferences`, widget storage, source code, or logs. Widgets are display-only and never make authenticated API calls. Report forms must not collect passwords, MFA codes, or other credentials.
