/// Riverpod providers for the authentication feature.
///
/// [authRepositoryProvider] supplies the repository implementation.
/// [authProvider] manages the sign-in / sign-out / session lifecycle.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Provides the [AuthRepository] implementation.
///
/// Defaults to [MockAuthRepository] for local development.
/// Override this provider in tests or when connecting a real OIDC IdP.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

/// Manages the authentication lifecycle.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkExistingSession();
    return const AuthInitial();
  }

  /// Check if there are stored tokens from a previous session.
  Future<void> _checkExistingSession() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      final tokens = await repository.getStoredTokens();

      if (tokens == null || tokens.isExpired) {
        state = const AuthUnauthenticated();
        return;
      }

      // Tokens exist and are not expired — fetch user profile.
      final user = await repository.getCurrentUser(tokens.accessToken);
      state = AuthAuthenticated(user: user);
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  /// Initiate sign-in flow.
  Future<void> signIn() async {
    state = const AuthLoading();

    try {
      final repository = ref.read(authRepositoryProvider);
      final tokens = await repository.signIn();
      final user = await repository.getCurrentUser(tokens.accessToken);
      state = AuthAuthenticated(user: user);
    } catch (_) {
      state = const AuthError(
        failure: ServerFailure(
          message: 'Sign in failed. Please try again.',
          statusCode: 401,
        ),
      );
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();
    } catch (_) {
      // Best-effort: clear local state even if backend call fails.
    }

    state = const AuthUnauthenticated();
  }

  /// Retry after an error — go back to unauthenticated.
  void dismissError() {
    state = const AuthUnauthenticated();
  }
}
