/// Domain failure types for Security Pulse.
///
/// These are sealed classes that represent every category of failure
/// that can occur in the application. They are returned by use cases
/// and mapped to user-visible error states in the presentation layer.
///
/// Never include authentication tokens, passwords, or PII in failure messages.
library;

sealed class Failure {
  const Failure({required this.message});
  final String message;
}

/// Network connectivity failure — no internet connection.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No network connection.'});
}

/// Server returned an error response (4xx or 5xx).
final class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    required this.statusCode,
    this.code,
  });
  final int statusCode;
  final String? code;
}

/// The user is not authenticated.
final class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure({super.message = 'Authentication required.'});
}

/// The user is authenticated but lacks permission.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Access denied.'});
}

/// A resource was not found.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Resource not found.'});
}

/// A duplicate submission was detected (idempotency).
final class ConflictFailure extends Failure {
  const ConflictFailure({
    super.message = 'This action has already been recorded.',
  });
}

/// Input validation failed.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    this.fieldErrors = const {},
  });
  final Map<String, String> fieldErrors;
}

/// An unexpected local error (e.g., secure storage failure).
final class LocalFailure extends Failure {
  const LocalFailure({super.message = 'A local error occurred.'});
}
