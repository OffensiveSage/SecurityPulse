/// Riverpod providers for the incident report form.
///
/// [incidentRepositoryProvider] supplies the repository implementation.
/// [incidentFormProvider] manages the form lifecycle.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/mock_incident_repository.dart';
import '../../domain/models/report_type.dart';
import '../../domain/repositories/incident_repository.dart';
import 'incident_form_state.dart';

/// Provides the [IncidentRepository] implementation.
///
/// Defaults to [MockIncidentRepository] for local development.
/// Override with [ApiIncidentRepository] when the backend is available.
final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return MockIncidentRepository();
});

/// Manages the incident report form lifecycle.
///
/// AutoDispose clears form state when the user navigates away.
final incidentFormProvider =
    NotifierProvider.autoDispose<IncidentFormNotifier, IncidentFormState>(
  IncidentFormNotifier.new,
);

class IncidentFormNotifier extends AutoDisposeNotifier<IncidentFormState> {
  @override
  IncidentFormState build() {
    return IncidentFormEditing(occurredAt: DateTime.now());
  }

  /// Updates the selected report type and clears conditional metadata.
  void updateReportType(ReportType type) {
    final current = state;
    if (current is IncidentFormEditing) {
      state = current.copyWith(
        reportType: type,
        metadataFields: {},
        validationErrors: {},
      );
    }
  }

  /// Updates the title field.
  void updateTitle(String title) {
    final current = state;
    if (current is IncidentFormEditing) {
      state = current.copyWith(title: title, validationErrors: {});
    }
  }

  /// Updates the description field.
  void updateDescription(String description) {
    final current = state;
    if (current is IncidentFormEditing) {
      state = current.copyWith(description: description, validationErrors: {});
    }
  }

  /// Updates the date/time of occurrence.
  void updateOccurredAt(DateTime occurredAt) {
    final current = state;
    if (current is IncidentFormEditing) {
      state = current.copyWith(occurredAt: occurredAt, validationErrors: {});
    }
  }

  /// Updates the severity selection.
  void updateSeverity(IncidentSeverity? severity) {
    final current = state;
    if (current is IncidentFormEditing) {
      state = current.copyWith(
        severity: () => severity,
        validationErrors: {},
      );
    }
  }

  /// Updates a single metadata field.
  void updateMetadataField(String key, dynamic value) {
    final current = state;
    if (current is IncidentFormEditing) {
      final updated = Map<String, dynamic>.from(current.metadataFields);
      if (value == null || (value is String && value.isEmpty)) {
        updated.remove(key);
      } else {
        updated[key] = value;
      }
      state = current.copyWith(metadataFields: updated, validationErrors: {});
    }
  }

  /// Validates the form and returns true if valid.
  bool validate() {
    final current = state;
    if (current is! IncidentFormEditing) return false;

    final errors = <String, String>{};

    if (current.reportType == null) {
      errors['reportType'] = 'Report type is required';
    }

    if (current.title.length < 5 || current.title.length > 100) {
      errors['title'] = 'Title must be 5\u2013100 characters';
    }

    if (current.description.length < 10 || current.description.length > 2000) {
      errors['description'] = 'Description must be 10\u20132000 characters';
    }

    if (current.occurredAt == null) {
      errors['occurredAt'] = 'Date and time is required';
    } else if (current.occurredAt!.isAfter(
      DateTime.now().add(const Duration(minutes: 5)),
    )) {
      errors['occurredAt'] = 'Date cannot be in the future';
    }

    if (errors.isNotEmpty) {
      state = current.copyWith(validationErrors: errors);
      return false;
    }

    return true;
  }

  /// Submits the report.
  Future<void> submit() async {
    if (!validate()) return;

    final editing = state as IncidentFormEditing;
    state = const IncidentFormSubmitting();

    try {
      final repository = ref.read(incidentRepositoryProvider);
      final reportId = await repository.submitReport(
        reportType: editing.reportType!, // safe: validated above
        title: editing.title,
        description: editing.description,
        occurredAt: editing.occurredAt!, // safe: validated above
        severity: editing.severity,
        metadataFields:
            editing.metadataFields.isEmpty ? null : editing.metadataFields,
      );

      state = IncidentFormSuccess(
        reportId: reportId,
        title: editing.title,
        reportType: editing.reportType!,
        submittedAt: DateTime.now(),
      );
    } on Failure catch (f) {
      state = IncidentFormError(failure: f, previousState: editing);
    } catch (_) {
      state = IncidentFormError(
        failure: const ServerFailure(
          message: 'Unable to submit report. Please try again.',
          statusCode: 500,
        ),
        previousState: editing,
      );
    }
  }

  /// Restores the previous editing state after an error.
  void retryFromError() {
    final current = state;
    if (current is IncidentFormError) {
      state = current.previousState;
    }
  }
}
