/// Abstract repository interface for authentication.
///
/// Implementations:
/// - [MockAuthRepository] for local development and testing.
/// - [OidcAuthRepository] for real OIDC flows with a corporate IdP.
library;

import '../models/auth_tokens.dart';
import '../models/user.dart';

/// Contract for authentication operations.
abstract class AuthRepository {
  /// Initiate sign-in flow and return tokens.
  ///
  /// For OIDC: launches the Authorization Code Flow with PKCE.
  /// For mock: returns fixed test tokens immediately.
  Future<AuthTokens> signIn();

  /// Sign out the current user and clear stored tokens.
  Future<void> signOut();

  /// Fetch the current user's profile from the backend.
  Future<User> getCurrentUser(String accessToken);

  /// Retrieve previously stored tokens from secure storage.
  ///
  /// Returns `null` if no tokens are stored (user never signed in).
  Future<AuthTokens?> getStoredTokens();

  /// Attempt to refresh the access token using the refresh token.
  ///
  /// Returns new tokens or throws if refresh fails.
  Future<AuthTokens> refreshTokens(String refreshToken);

  /// Clear all stored tokens from secure storage.
  Future<void> clearTokens();
}
