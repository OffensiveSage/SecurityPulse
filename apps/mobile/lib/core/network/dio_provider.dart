/// Riverpod provider for the configured Dio HTTP client.
///
/// Uses [createApiClient] with the auth interceptor from secure token storage.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/services/secure_token_storage.dart';
import 'api_client.dart';

/// The base URL for the Security Pulse API.
///
/// In development, the Android emulator uses 10.0.2.2 to reach the host.
/// This should be configurable via environment in production.
const _defaultBaseUrl = 'http://10.0.2.2:8000';

/// Provides a configured [Dio] instance for API requests.
///
/// The Dio client includes an auth interceptor that attaches the Bearer
/// token from secure storage and handles 401 responses.
final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = SecureTokenStorage();
  return createApiClient(
    baseUrl: _defaultBaseUrl,
    tokenStorage: tokenStorage,
  );
});
