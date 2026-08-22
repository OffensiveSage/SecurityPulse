/// Dio interceptor for transparent token attachment and refresh.
///
/// On each request: reads the access token from secure storage and
/// attaches it as a Bearer token in the Authorization header.
///
/// On 401 responses: attempts token refresh. If refresh succeeds,
/// retries the original request. If refresh fails, signals that the
/// session has expired.
///
/// Security: never logs token values.
library;

import 'package:dio/dio.dart';

import '../../features/auth/data/services/secure_token_storage.dart';

/// Callback invoked when token refresh fails and session is expired.
typedef OnSessionExpired = void Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureTokenStorage tokenStorage,
    this.onSessionExpired,
  }) : _tokenStorage = tokenStorage;

  final SecureTokenStorage _tokenStorage;

  /// Called when token refresh fails — the app should transition to
  /// unauthenticated state.
  final OnSessionExpired? onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      onSessionExpired?.call();
    }
    handler.next(err);
  }
}
