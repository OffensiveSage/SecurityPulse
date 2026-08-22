/// Configured Dio HTTP client for API requests.
///
/// Includes:
/// - [AuthInterceptor] for automatic Bearer token attachment.
/// - X-Correlation-Id header for request tracing.
library;

import 'dart:math';

import 'package:dio/dio.dart';

import '../../features/auth/data/services/secure_token_storage.dart';
import 'auth_interceptor.dart';

/// Creates a configured Dio instance for Security Pulse API requests.
Dio createApiClient({
  required String baseUrl,
  required SecureTokenStorage tokenStorage,
  AuthInterceptor? authInterceptor,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Auth interceptor for token attachment + 401 handling.
  dio.interceptors.add(
    authInterceptor ?? AuthInterceptor(tokenStorage: tokenStorage),
  );

  // Correlation ID interceptor for request tracing.
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['X-Correlation-Id'] = _generateCorrelationId();
        handler.next(options);
      },
    ),
  );

  return dio;
}

/// Generates a simple correlation ID for request tracing.
String _generateCorrelationId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
