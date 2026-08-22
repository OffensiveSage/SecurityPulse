/// Riverpod provider for response history.
///
/// Manages the lifecycle of fetching and displaying the user's
/// scenario response history.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/models/response_record.dart';
import 'daily_scenario_provider.dart';

/// Sealed state hierarchy for the history feature.
@immutable
sealed class HistoryState {
  const HistoryState();
}

final class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

final class HistoryLoaded extends HistoryState {
  const HistoryLoaded({required this.records});
  final List<ResponseRecord> records;
}

final class HistoryEmpty extends HistoryState {
  const HistoryEmpty();
}

final class HistoryError extends HistoryState {
  const HistoryError({required this.failure});
  final Failure failure;
}

/// Manages the history state: loading -> loaded/empty/error.
final historyProvider =
    NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    _loadHistory();
    return const HistoryLoading();
  }

  Future<void> _loadHistory() async {
    try {
      final repository = ref.read(scenarioRepositoryProvider);
      final records = await repository.getHistory();
      if (records.isEmpty) {
        state = const HistoryEmpty();
      } else {
        state = HistoryLoaded(records: records);
      }
    } on NetworkFailure {
      state = const HistoryError(
        failure: NetworkFailure(),
      );
    } catch (_) {
      state = const HistoryError(
        failure: ServerFailure(
          message: 'Unable to load history. Please try again.',
          statusCode: 500,
        ),
      );
    }
  }

  /// Retries loading history after an error.
  Future<void> retry() async {
    state = const HistoryLoading();
    await _loadHistory();
  }
}
