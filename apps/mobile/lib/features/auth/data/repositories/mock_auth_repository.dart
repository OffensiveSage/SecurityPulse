/// Mock implementation of [AuthRepository] for local development.
///
/// Returns a fixed test employee user without requiring a real
/// identity provider or backend. Used when OIDC IdP is not available.
library;

import '../../domain/models/auth_tokens.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/secure_token_storage.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({SecureTokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? SecureTokenStorage();

  final SecureTokenStorage _tokenStorage;

  static const _mockUser = User(
    id: 'mock-user-001',
    displayName: 'Test Employee',
    email: 'employee@example.corp',
    role: UserRole.employee,
  );

  @override
  Future<AuthTokens> signIn() async {
    // Simulate sign-in delay.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final tokens = AuthTokens(
      accessToken: 'mock-employee',
      refreshToken: 'mock-refresh-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
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
  }

  @override
  Future<User> getCurrentUser(String accessToken) async {
    // Simulate network delay.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _mockUser;
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
    // Mock refresh: return new tokens.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final tokens = AuthTokens(
      accessToken: 'mock-employee',
      refreshToken: 'mock-refresh-token-refreshed',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
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
