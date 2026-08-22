/// API-backed implementation of [IncidentRepository].
///
/// Communicates with the FastAPI backend for incident report
/// creation, listing, and detail retrieval.
library;

import 'dart:math';

import 'package:dio/dio.dart';

import '../../../scenario/data/mappers/dio_error_mapper.dart';
import '../../domain/models/incident_report.dart';
import '../../domain/models/report_type.dart';
import '../../domain/repositories/incident_repository.dart';

class ApiIncidentRepository implements IncidentRepository {
  ApiIncidentRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<String> submitReport({
    required ReportType reportType,
    required String title,
    required String description,
    required DateTime occurredAt,
    IncidentSeverity? severity,
    Map<String, dynamic>? metadataFields,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/incidents',
        data: {
          'report_type': reportType.apiValue,
          'title': title,
          'description': description,
          'occurred_at': occurredAt.toUtc().toIso8601String(),
          if (severity != null) 'severity': severity.apiValue,
          if (metadataFields != null) 'metadata_fields': metadataFields,
        },
        options: Options(
          headers: {
            'Idempotency-Key': _generateIdempotencyKey(),
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return data['report_id'] as String;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<IncidentReportSummary>> getMyReports({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/incidents/mine',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final items = data['data'] as List<dynamic>;

      return items
          .map(
            (e) => IncidentReportSummary.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<IncidentReport> getReportById(String id) async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/incidents/$id');
      return IncidentReport.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  String _generateIdempotencyKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
