import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:security_pulse/core/error/failures.dart';
import 'package:security_pulse/core/l10n/app_localizations.dart';
import 'package:security_pulse/core/widgets/error_view.dart';
import 'package:security_pulse/core/widgets/loading_view.dart';
import 'package:security_pulse/features/auth/presentation/providers/auth_provider.dart';
import 'package:security_pulse/features/auth/presentation/providers/auth_state.dart';
import 'package:security_pulse/features/auth/presentation/screens/sign_in_screen.dart';

/// Builds a test app with the [SignInScreen] pinned to a fixed auth state.
Widget _buildWithFixedState(AuthState state) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FixedAuthNotifier(state)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SignInScreen(),
    ),
  );
}

/// A notifier that returns a fixed state without loading from a repository.
class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._fixedState);
  final AuthState _fixedState;

  @override
  AuthState build() => _fixedState;
}

void main() {
  group('SignInScreen', () {
    group('unauthenticated state', () {
      testWidgets('shows sign-in button', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const AuthUnauthenticated()),
        );
        await tester.pump();

        expect(
          find.text('Sign in with your company account'),
          findsOneWidget,
        );
      });

      testWidgets('shows app name', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const AuthUnauthenticated()),
        );
        await tester.pump();

        expect(find.text('Security Pulse'), findsOneWidget);
      });

      testWidgets('shows subtitle', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const AuthUnauthenticated()),
        );
        await tester.pump();

        // The subtitle appears in both the hero section and the bottom card.
        expect(
          find.text('Corporate cybersecurity awareness'),
          findsWidgets,
        );
      });

      testWidgets('shows privacy note', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const AuthUnauthenticated()),
        );
        await tester.pump();

        expect(
          find.textContaining('acceptable use policy'),
          findsOneWidget,
        );
      });

      testWidgets('shows security icon', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const AuthUnauthenticated()),
        );
        await tester.pump();

        // The sign-in hero uses shield_rounded as the main security icon.
        expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
      });
    });

    group('initial state', () {
      testWidgets('shows sign-in body (same as unauthenticated)',
          (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const AuthInitial()),
        );
        await tester.pump();

        expect(
          find.text('Sign in with your company account'),
          findsOneWidget,
        );
      });
    });

    group('loading state', () {
      testWidgets('shows loading indicator during sign-in', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const AuthLoading()),
        );
        await tester.pump();

        expect(find.byType(LoadingView), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows signing in message', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const AuthLoading()),
        );
        await tester.pump();

        expect(find.textContaining('Signing in'), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error view', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const AuthError(
              failure: ServerFailure(
                message: 'Sign in failed',
                statusCode: 401,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ErrorView), findsOneWidget);
      });

      testWidgets('shows retry button', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const AuthError(
              failure: ServerFailure(
                message: 'Sign in failed',
                statusCode: 401,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Try again'), findsOneWidget);
      });
    });
  });
}
