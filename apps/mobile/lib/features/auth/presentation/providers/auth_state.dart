/// State classes for the authentication feature.
///
/// Uses sealed classes for exhaustive pattern matching in the UI.
library;

import '../../../../core/error/failures.dart';
import '../../domain/models/user.dart';

/// All possible states for the authentication lifecycle.
sealed class AuthState {
  const AuthState();
}

/// Initial state — checking for an existing session.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Authentication is in progress (sign-in or session restore).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated and has a valid session.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});

  /// The authenticated user.
  final User user;
}

/// User is not authenticated (no session or signed out).
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An error occurred during authentication.
final class AuthError extends AuthState {
  const AuthError({required this.failure});

  /// The failure that occurred.
  final Failure failure;
}
