/// Riverpod provider for incident report history.
///
/// Manages the lifecycle of fetching and displaying the user's
/// incident report history.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/models/incident_report.dart';
import 'incident_form_provider.dart';

/// Sealed state hierarchy for incident history.
@immutable
sealed class IncidentHistoryState {
  const IncidentHistoryState();
}

final class IncidentHistoryLoading extends IncidentHistoryState {
  const IncidentHistoryLoading();
}

final class IncidentHistoryLoaded extends IncidentHistoryState {
  const IncidentHistoryLoaded({required this.reports});
  final List<IncidentReportSummary> reports;
}

final class IncidentHistoryEmpty extends IncidentHistoryState {
  const IncidentHistoryEmpty();
}

final class IncidentHistoryError extends IncidentHistoryState {
  const IncidentHistoryError({required this.failure});
  final Failure failure;
}

/// Manages incident history state: loading -> loaded/empty/error.
final incidentHistoryProvider =
    NotifierProvider<IncidentHistoryNotifier, IncidentHistoryState>(
  IncidentHistoryNotifier.new,
);

class IncidentHistoryNotifier extends Notifier<IncidentHistoryState> {
  @override
  IncidentHistoryState build() {
    _loadReports();
    return const IncidentHistoryLoading();
  }

  Future<void> _loadReports() async {
    try {
      final repository = ref.read(incidentRepositoryProvider);
      final reports = await repository.getMyReports();
      if (reports.isEmpty) {
        state = const IncidentHistoryEmpty();
      } else {
        state = IncidentHistoryLoaded(reports: reports);
      }
    } on NetworkFailure {
      state = const IncidentHistoryError(
        failure: NetworkFailure(),
      );
    } catch (_) {
      state = const IncidentHistoryError(
        failure: ServerFailure(
          message: 'Unable to load reports. Please try again.',
          statusCode: 500,
        ),
      );
    }
  }

  /// Retries loading reports after an error.
  Future<void> retry() async {
    state = const IncidentHistoryLoading();
    await _loadReports();
  }
}
