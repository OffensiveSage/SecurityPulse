/// Value object for authentication tokens.
///
/// Stores access and refresh tokens with expiry tracking.
/// Token values are never logged or stored in plain SharedPreferences.
library;

import 'package:flutter/foundation.dart';

/// Holds the OIDC tokens received after authentication.
@immutable
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
  });

  /// The short-lived access token for API requests.
  final String accessToken;

  /// The optional long-lived refresh token.
  final String? refreshToken;

  /// When the access token expires.
  final DateTime expiresAt;

  /// Whether the access token has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
