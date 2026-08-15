/// Real OIDC implementation of [AuthRepository].
///
/// Uses flutter_appauth for Authorization Code Flow with PKCE.
/// Stores tokens in flutter_secure_storage (never SharedPreferences).
///
/// This implementation requires a configured OIDC identity provider.
/// The [AuthConfig] provides issuer URL, client ID, and redirect URI.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import '../../domain/models/auth_tokens.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_config.dart';
import '../services/secure_token_storage.dart';

class OidcAuthRepository implements AuthRepository {
  OidcAuthRepository({
    required AuthConfig config,
    FlutterAppAuth? appAuth,
    SecureTokenStorage? tokenStorage,
  })  : _config = config,
        _appAuth = appAuth ?? const FlutterAppAuth(),
        _tokenStorage = tokenStorage ?? SecureTokenStorage();

  final AuthConfig _config;
  final FlutterAppAuth _appAuth;
  final SecureTokenStorage _tokenStorage;

  @override
  Future<AuthTokens> signIn() async {
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _config.clientId,
        _config.redirectUri,
        issuer: _config.issuerUrl,
        scopes: _config.scopes,
        allowInsecureConnections: kDebugMode,
      ),
    );

    final accessToken = result.accessToken;
    final expiresAt = result.accessTokenExpirationDateTime;
    if (accessToken == null || expiresAt == null) {
      throw Exception('OIDC sign-in failed: no tokens received.');
    }

    final tokens = AuthTokens(
      accessToken: accessToken,
      refreshToken: result.refreshToken,
      expiresAt: expiresAt,
    );

    // Persist tokens to secure storage.
    await _tokenStorage.writeAccessToken(tokens.accessToken);
    if (tokens.refreshToken != null) {
      await _tokenStorage
          .writeRefreshToken(tokens.refreshToken!); // safe: checked above
    }
    await _tokenStorage.writeExpiresAt(tokens.expiresAt);

    return tokens;
  }

  @override
  Future<void> signOut() async {
    await _tokenStorage.clearAll();
    // POST to /api/v1/auth/logout would go here with an HTTP client.
    // For Phase 2, server-side logout is a no-op (stateless JWT).
  }

  @override
  Future<User> getCurrentUser(String accessToken) async {
    // In a real implementation, this calls GET /api/v1/auth/me
    // with the Bearer token. For now, decode the JWT to extract
    // basic user info.
    try {
      final parts = accessToken.split('.');
      if (parts.length == 3) {
        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        ) as Map<String, dynamic>;

        return User(
          id: (payload['sub'] as String?) ?? '',
          displayName: payload['name'] as String?,
          email: payload['email'] as String?,
          role: UserRole.fromString(
            (payload['role'] as String?) ?? 'employee',
          ),
        );
      }
    } on Exception {
      // If JWT parsing fails, return a minimal user.
    }

    return const User(id: '', role: UserRole.employee);
  }

  @override
  Future<AuthTokens?> getStoredTokens() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null) return null;

    final expiresAt = await _tokenStorage.readExpiresAt();
    final refreshToken = await _tokenStorage.readRefreshToken();

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt ?? DateTime.now(),
    );
  }

  @override
  Future<AuthTokens> refreshTokens(String refreshToken) async {
    final result = await _appAuth.token(
      TokenRequest(
        _config.clientId,
        _config.redirectUri,
        issuer: _config.issuerUrl,
        refreshToken: refreshToken,
        scopes: _config.scopes,
        allowInsecureConnections: kDebugMode,
      ),
    );

    final accessToken = result.accessToken;
    final expiresAt = result.accessTokenExpirationDateTime;
    if (accessToken == null || expiresAt == null) {
      throw Exception('Token refresh failed: no tokens received.');
    }

    final tokens = AuthTokens(
      accessToken: accessToken,
      refreshToken: result.refreshToken ?? refreshToken,
      expiresAt: expiresAt,
    );

    await _tokenStorage.writeAccessToken(tokens.accessToken);
    if (tokens.refreshToken != null) {
      await _tokenStorage
          .writeRefreshToken(tokens.refreshToken!); // safe: checked above
    }
    await _tokenStorage.writeExpiresAt(tokens.expiresAt);

    return tokens;
  }

  @override
  Future<void> clearTokens() async {
    await _tokenStorage.clearAll();
  }
}
