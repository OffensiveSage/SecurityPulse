/// State classes for the daily scenario feature.
///
/// Uses sealed classes for exhaustive pattern matching in the UI.
/// Every screen state (loading, empty, error, offline, loaded, submitting,
/// completed) is represented.
library;

import '../../../../core/error/failures.dart';
import '../../domain/models/scenario.dart';

/// All possible states for the daily scenario screen.
sealed class DailyScenarioState {
  const DailyScenarioState();
}

/// Scenario is being fetched from the repository.
final class DailyScenarioLoading extends DailyScenarioState {
  const DailyScenarioLoading();
}

/// No scenario is assigned to the employee today.
final class DailyScenarioEmpty extends DailyScenarioState {
  const DailyScenarioEmpty();
}

/// Scenario loaded and ready for the employee to answer.
final class DailyScenarioLoaded extends DailyScenarioState {
  const DailyScenarioLoaded({
    required this.scenario,
    this.selectedOptionId,
  });

  /// The scenario to display.
  final Scenario scenario;

  /// The currently selected answer option, if any.
  final String? selectedOptionId;
}

/// Answer is being submitted to the server.
final class DailyScenarioSubmitting extends DailyScenarioState {
  const DailyScenarioSubmitting({
    required this.scenario,
    required this.selectedOptionId,
  });

  final Scenario scenario;
  final String selectedOptionId;
}

/// Answer has been submitted and the result is available.
final class DailyScenarioCompleted extends DailyScenarioState {
  const DailyScenarioCompleted({
    required this.scenario,
    required this.result,
  });

  final Scenario scenario;
  final ScenarioResult result;
}

/// A recoverable error occurred while loading or submitting.
final class DailyScenarioError extends DailyScenarioState {
  const DailyScenarioError({required this.failure});
  final Failure failure;
}

/// Device is offline — no network connectivity.
final class DailyScenarioOffline extends DailyScenarioState {
  const DailyScenarioOffline();
}
