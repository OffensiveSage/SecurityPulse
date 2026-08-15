/// Domain model representing an authenticated platform user.
///
/// This model contains only display-safe identity information.
/// Tokens are never stored in this model.
library;

import 'package:flutter/foundation.dart';

/// Roles supported in Phase 2.
enum UserRole {
  employee,
  contentAdmin,
  securityAdmin;

  /// Parse a role string from the API (e.g. 'content_admin').
  static UserRole fromString(String value) {
    return switch (value) {
      'employee' => UserRole.employee,
      'content_admin' => UserRole.contentAdmin,
      'security_admin' => UserRole.securityAdmin,
      _ => UserRole.employee,
    };
  }

  /// Serialize to API format.
  String toApiString() {
    return switch (this) {
      UserRole.employee => 'employee',
      UserRole.contentAdmin => 'content_admin',
      UserRole.securityAdmin => 'security_admin',
    };
  }
}

/// An authenticated user on the Security Pulse platform.
@immutable
class User {
  const User({
    required this.id,
    required this.role,
    this.displayName,
    this.email,
  });

  /// Unique user identifier (UUID from the backend).
  final String id;

  /// Display name from the identity provider.
  final String? displayName;

  /// Email address from the identity provider.
  final String? email;

  /// The user's role for authorization purposes.
  final UserRole role;
}
