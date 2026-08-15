/// Secure token storage using flutter_secure_storage.
///
/// Wraps [FlutterSecureStorage] to enforce security rules:
/// - Tokens are stored in iOS Keychain / Android EncryptedSharedPreferences.
/// - Token values are never logged.
/// - Never uses plain SharedPreferences.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys used for storing auth tokens. Prefixed to avoid collisions.
class _StorageKeys {
  static const accessToken = 'sp_access_token';
  static const refreshToken = 'sp_refresh_token';
  static const expiresAt = 'sp_expires_at';
}

/// Manages secure read/write/clear of authentication tokens.
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  /// Store the access token.
  Future<void> writeAccessToken(String token) async {
    await _storage.write(key: _StorageKeys.accessToken, value: token);
  }

  /// Read the stored access token, or `null` if not set.
  Future<String?> readAccessToken() async {
    return _storage.read(key: _StorageKeys.accessToken);
  }

  /// Store the refresh token.
  Future<void> writeRefreshToken(String token) async {
    await _storage.write(key: _StorageKeys.refreshToken, value: token);
  }

  /// Read the stored refresh token, or `null` if not set.
  Future<String?> readRefreshToken() async {
    return _storage.read(key: _StorageKeys.refreshToken);
  }

  /// Store the token expiry timestamp as ISO-8601.
  Future<void> writeExpiresAt(DateTime expiresAt) async {
    await _storage.write(
      key: _StorageKeys.expiresAt,
      value: expiresAt.toIso8601String(),
    );
  }

  /// Read the stored expiry timestamp, or `null` if not set.
  Future<DateTime?> readExpiresAt() async {
    final value = await _storage.read(key: _StorageKeys.expiresAt);
    return value != null ? DateTime.tryParse(value) : null;
  }

  /// Clear all stored tokens. Called on sign-out.
  Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _StorageKeys.accessToken),
      _storage.delete(key: _StorageKeys.refreshToken),
      _storage.delete(key: _StorageKeys.expiresAt),
    ]);
  }
}
