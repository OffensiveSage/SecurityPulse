import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:security_pulse/core/l10n/app_localizations.dart';
import 'package:security_pulse/core/router/app_router.dart';
import 'package:security_pulse/features/auth/presentation/providers/auth_provider.dart';
import 'package:security_pulse/features/auth/presentation/providers/auth_state.dart';
import 'package:security_pulse/features/scenario/domain/repositories/scenario_repository.dart';
import 'package:security_pulse/features/scenario/presentation/providers/daily_scenario_provider.dart';

class _MockScenarioRepository extends Mock implements ScenarioRepository {}

/// A notifier that returns a fixed auth state without loading from a repository.
class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._fixedState);
  final AuthState _fixedState;

  @override
  AuthState build() => _fixedState;
}

void main() {
  group('GoRouter auth guard', () {
    testWidgets(
      'redirects unauthenticated user to sign-in',
      (tester) async {
        final router = createAppRouter(
          isAuthenticated: () => false,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                () => _FixedAuthNotifier(const AuthUnauthenticated()),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should be redirected to sign-in screen.
        expect(
          find.text('Sign in with your company account'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'allows authenticated user to access home',
      (tester) async {
        final mockRepo = _MockScenarioRepository();
        // ignore: unnecessary_lambdas
        when(() => mockRepo.getTodayScenario()).thenAnswer((_) async => null);

        final router = createAppRouter(
          isAuthenticated: () => true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              scenarioRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should see the home screen (DailyScenarioScreen), not sign-in.
        expect(
          find.text('Sign in with your company account'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'redirects authenticated user away from sign-in to home',
      (tester) async {
        final mockRepo = _MockScenarioRepository();
        // ignore: unnecessary_lambdas
        when(() => mockRepo.getTodayScenario()).thenAnswer((_) async => null);

        final router = createAppRouter(
          isAuthenticated: () => true,
        );

        // Navigate to sign-in (should be redirected to home).
        router.go('/sign-in');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              scenarioRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should NOT see sign-in screen.
        expect(
          find.text('Sign in with your company account'),
          findsNothing,
        );
      },
    );
  });
}
