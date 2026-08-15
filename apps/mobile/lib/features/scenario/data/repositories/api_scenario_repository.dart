/// API-backed implementation of [ScenarioRepository].
///
/// Communicates with the FastAPI backend for scenario delivery,
/// response submission, history, and progress.
///
/// Security:
/// - Idempotency-Key header on response submission (T-04).
/// - Scenario JSON from API never contains is_correct before submission (T-03).
library;

import 'dart:math';

import 'package:dio/dio.dart';

import '../../domain/models/response_record.dart';
import '../../domain/models/scenario.dart';
import '../../domain/models/user_progress.dart';
import '../../domain/repositories/scenario_repository.dart';
import '../mappers/dio_error_mapper.dart';

class ApiScenarioRepository implements ScenarioRepository {
  ApiScenarioRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<Scenario?> getTodayScenario() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/scenarios/today');

      if (response.statusCode == 204 || response.data == null) {
        return null;
      }

      return Scenario.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 204) {
        return null;
      }
      throw mapDioError(e);
    }
  }

  @override
  Future<ScenarioResult> submitAnswer({
    required String scenarioId,
    required String selectedOptionId,
  }) async {
    try {
      // Submit the response with an idempotency key
      await _dio.post<dynamic>(
        '/api/v1/scenarios/$scenarioId/responses',
        data: {
          'selected_option_id': selectedOptionId,
        },
        options: Options(
          headers: {
            'Idempotency-Key': _generateIdempotencyKey(),
          },
        ),
      );

      // Fetch the result (includes correct answers after submission)
      final resultResponse = await _dio.get<dynamic>(
        '/api/v1/scenarios/$scenarioId/result',
      );

      return ScenarioResult.fromJson(
        resultResponse.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<ResponseRecord>> getHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/me/history',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final items = data['data'] as List<dynamic>;

      return items
          .map((e) => ResponseRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<UserProgress> getProgress() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/me/progress');
      return UserProgress.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Generates a unique idempotency key for submission requests.
  String _generateIdempotencyKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
