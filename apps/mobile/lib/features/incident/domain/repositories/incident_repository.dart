/// Abstract repository interface for incident reporting.
///
/// Concrete implementations:
/// - [MockIncidentRepository] for local development.
/// - [ApiIncidentRepository] when the backend is available.
library;

import '../models/incident_report.dart';
import '../models/report_type.dart';

/// Contract for incident report data access.
abstract class IncidentRepository {
  /// Submit a new incident report.
  ///
  /// Returns the report ID on success.
  Future<String> submitReport({
    required ReportType reportType,
    required String title,
    required String description,
    required DateTime occurredAt,
    IncidentSeverity? severity,
    Map<String, dynamic>? metadataFields,
  });

  /// Get the current user's incident reports, paginated.
  Future<List<IncidentReportSummary>> getMyReports({
    int page = 1,
    int pageSize = 20,
  });

  /// Get a single incident report by ID.
  Future<IncidentReport> getReportById(String id);
}
