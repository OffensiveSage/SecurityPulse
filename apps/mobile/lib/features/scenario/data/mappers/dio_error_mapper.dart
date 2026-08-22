/// Maps [DioException] to domain [Failure] types.
///
/// This mapper translates HTTP error responses and connectivity issues
/// into the sealed [Failure] hierarchy used by the presentation layer.
library;

import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';

/// Converts a [DioException] into the appropriate [Failure] subtype.
Failure mapDioError(DioException error) {
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError) {
    return const NetworkFailure();
  }

  final statusCode = error.response?.statusCode;
  if (statusCode == null) {
    return const NetworkFailure();
  }

  final detail = _extractDetail(error);

  return switch (statusCode) {
    401 => const UnauthenticatedFailure(),
    403 => UnauthorizedFailure(message: detail),
    404 => NotFoundFailure(message: detail),
    409 => ConflictFailure(message: detail),
    410 => ServerFailure(message: detail, statusCode: 410),
    429 => RateLimitFailure(message: detail),
    _ => ServerFailure(message: detail, statusCode: statusCode),
  };
}

String _extractDetail(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final detail = data['detail'];
    if (detail is String) return detail;
  }
  return 'An unexpected error occurred.';
}
