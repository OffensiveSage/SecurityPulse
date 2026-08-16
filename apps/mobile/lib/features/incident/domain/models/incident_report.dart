/// Domain models for incident reports.
///
/// [IncidentReport] is the full detail model.
/// [IncidentReportSummary] is the lightweight list-item model.
library;

import 'package:flutter/foundation.dart';

import 'report_type.dart';

/// Full incident report detail.
@immutable
class IncidentReport {
  const IncidentReport({
    required this.id,
    required this.reportType,
    required this.title,
    required this.description,
    required this.occurredAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.severity,
    this.metadataFields,
  });

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    return IncidentReport(
      id: json['id'] as String,
      reportType: ReportType.fromApi(json['report_type'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      severity: json['severity'] != null
          ? IncidentSeverity.fromApi(json['severity'] as String)
          : null,
      metadataFields: json['metadata_fields'] != null
          ? Map<String, dynamic>.from(json['metadata_fields'] as Map)
          : null,
      status: IncidentStatus.fromApi(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final ReportType reportType;
  final String title;
  final String description;
  final DateTime occurredAt;
  final IncidentSeverity? severity;
  final Map<String, dynamic>? metadataFields;
  final IncidentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Lightweight summary for list views.
@immutable
class IncidentReportSummary {
  const IncidentReportSummary({
    required this.id,
    required this.reportType,
    required this.title,
    required this.status,
    required this.createdAt,
    this.severity,
  });

  factory IncidentReportSummary.fromJson(Map<String, dynamic> json) {
    return IncidentReportSummary(
      id: json['id'] as String,
      reportType: ReportType.fromApi(json['report_type'] as String),
      title: json['title'] as String,
      severity: json['severity'] != null
          ? IncidentSeverity.fromApi(json['severity'] as String)
          : null,
      status: IncidentStatus.fromApi(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final ReportType reportType;
  final String title;
  final IncidentSeverity? severity;
  final IncidentStatus status;
  final DateTime createdAt;
}
