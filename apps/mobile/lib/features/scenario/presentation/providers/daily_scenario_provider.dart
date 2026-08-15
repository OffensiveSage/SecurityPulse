/// Riverpod providers for the daily scenario feature.
///
/// [scenarioRepositoryProvider] supplies the repository implementation.
/// [dailyScenarioProvider] manages the full question->answer->result lifecycle.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/mock_scenario_repository.dart';
import '../../domain/repositories/scenario_repository.dart';
import 'daily_scenario_state.dart';

/// Provides the [ScenarioRepository] implementation.
///
/// Defaults to [MockScenarioRepository] for local development.
/// Override this provider with [ApiScenarioRepository] when the backend
/// is available, or in tests with a mock implementation.
final scenarioRepositoryProvider = Provider<ScenarioRepository>((ref) {
  return MockScenarioRepository();
});

/// Manages the daily scenario lifecycle: load -> select -> submit -> result.
final dailyScenarioProvider =
    NotifierProvider<DailyScenarioNotifier, DailyScenarioState>(
  DailyScenarioNotifier.new,
);

class DailyScenarioNotifier extends Notifier<DailyScenarioState> {
  @override
  DailyScenarioState build() {
    _loadScenario();
    return const DailyScenarioLoading();
  }

  /// Fetches today's scenario from the repository.
  Future<void> _loadScenario() async {
    try {
      final repository = ref.read(scenarioRepositoryProvider);
      final scenario = await repository.getTodayScenario();
      if (scenario == null) {
        state = const DailyScenarioEmpty();
      } else {
        state = DailyScenarioLoaded(scenario: scenario);
      }
    } on NetworkFailure {
      state = const DailyScenarioOffline();
    } catch (_) {
      state = const DailyScenarioError(
        failure: ServerFailure(
          message: 'Unable to load today\u2019s scenario. Please try again.',
          statusCode: 500,
        ),
      );
    }
  }

  /// Selects an answer option. Only valid in the [DailyScenarioLoaded] state.
  void selectOption(String optionId) {
    final current = state;
    if (current is DailyScenarioLoaded) {
      state = DailyScenarioLoaded(
        scenario: current.scenario,
        selectedOptionId: optionId,
      );
    }
  }

  /// Submits the selected answer. Transitions through submitting -> completed.
  ///
  /// On failure, reverts to loaded state so the employee can retry.
  Future<void> submitAnswer() async {
    final current = state;
    if (current is! DailyScenarioLoaded) return;

    final selectedId = current.selectedOptionId;
    if (selectedId == null) return;

    state = DailyScenarioSubmitting(
      scenario: current.scenario,
      selectedOptionId: selectedId,
    );

    try {
      final repository = ref.read(scenarioRepositoryProvider);
      final result = await repository.submitAnswer(
        scenarioId: current.scenario.id,
        selectedOptionId: selectedId,
      );
      state = DailyScenarioCompleted(
        scenario: current.scenario,
        result: result,
      );
    } catch (_) {
      // Revert to loaded state so the employee can retry submission.
      state = DailyScenarioLoaded(
        scenario: current.scenario,
        selectedOptionId: selectedId,
      );
    }
  }

  /// Retries loading the scenario after an error or offline state.
  Future<void> retry() async {
    state = const DailyScenarioLoading();
    await _loadScenario();
  }
}
