/// OIDC configuration for the identity provider.
///
/// All values are loaded from environment variables or build configuration.
/// No hardcoded corporate IdP details — these are placeholders.
library;

import 'package:flutter/foundation.dart';

/// Configuration required for OIDC Authorization Code Flow with PKCE.
@immutable
class AuthConfig {
  const AuthConfig({
    required this.issuerUrl,
    required this.clientId,
    required this.redirectUri,
    this.scopes = const ['openid', 'profile', 'email'],
    this.postLogoutRedirectUri,
  });

  /// OIDC issuer URL (e.g. https://idp.example.com).
  final String issuerUrl;

  /// OAuth 2.0 client ID registered with the IdP.
  final String clientId;

  /// Redirect URI registered for the mobile app.
  final String redirectUri;

  /// OAuth scopes to request.
  final List<String> scopes;

  /// Redirect URI after logout (optional).
  final String? postLogoutRedirectUri;
}
