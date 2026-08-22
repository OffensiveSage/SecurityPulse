/// State classes for the incident report form.
///
/// Uses sealed classes for exhaustive pattern matching in the UI.
/// States: editing, submitting, success, error.
library;

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/models/report_type.dart';

/// All possible states for the incident report form.
@immutable
sealed class IncidentFormState {
  const IncidentFormState();
}

/// Form is being edited by the user.
final class IncidentFormEditing extends IncidentFormState {
  const IncidentFormEditing({
    this.reportType,
    this.title = '',
    this.description = '',
    this.occurredAt,
    this.severity,
    this.metadataFields = const {},
    this.validationErrors = const {},
  });

  final ReportType? reportType;
  final String title;
  final String description;
  final DateTime? occurredAt;
  final IncidentSeverity? severity;
  final Map<String, dynamic> metadataFields;
  final Map<String, String> validationErrors;

  /// Whether to show the urgent guidance banner.
  bool get showUrgentGuidance =>
      severity == IncidentSeverity.critical ||
      reportType == ReportType.unauthorizedAccess ||
      reportType == ReportType.dataExposure;

  /// Creates a copy with the given fields replaced.
  IncidentFormEditing copyWith({
    ReportType? reportType,
    String? title,
    String? description,
    DateTime? occurredAt,
    IncidentSeverity? Function()? severity,
    Map<String, dynamic>? metadataFields,
    Map<String, String>? validationErrors,
  }) {
    return IncidentFormEditing(
      reportType: reportType ?? this.reportType,
      title: title ?? this.title,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      severity: severity != null ? severity() : this.severity,
      metadataFields: metadataFields ?? this.metadataFields,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}

/// Report is being submitted to the server.
final class IncidentFormSubmitting extends IncidentFormState {
  const IncidentFormSubmitting();
}

/// Report was submitted successfully.
final class IncidentFormSuccess extends IncidentFormState {
  const IncidentFormSuccess({
    required this.reportId,
    required this.title,
    required this.reportType,
    required this.submittedAt,
  });

  final String reportId;
  final String title;
  final ReportType reportType;
  final DateTime submittedAt;
}

/// An error occurred during submission.
final class IncidentFormError extends IncidentFormState {
  const IncidentFormError({
    required this.failure,
    required this.previousState,
  });

  final Failure failure;

  /// The editing state before the error, for retry.
  final IncidentFormEditing previousState;
}
