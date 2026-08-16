/// Mock implementation of [IncidentRepository] for local development.
///
/// Returns empty data with simulated network delay.
/// Used in tests and development when no backend is available.
library;

import '../../domain/models/incident_report.dart';
import '../../domain/models/report_type.dart';
import '../../domain/repositories/incident_repository.dart';

class MockIncidentRepository implements IncidentRepository {
  @override
  Future<String> submitReport({
    required ReportType reportType,
    required String title,
    required String description,
    required DateTime occurredAt,
    IncidentSeverity? severity,
    Map<String, dynamic>? metadataFields,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    // Return a fake UUID.
    return 'mock-report-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<List<IncidentReportSummary>> getMyReports({
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return [];
  }

  @override
  Future<IncidentReport> getReportById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return IncidentReport(
      id: id,
      reportType: ReportType.other,
      title: 'Mock Report',
      description: 'This is a mock incident report for development.',
      occurredAt: DateTime.now(),
      status: IncidentStatus.submitted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
