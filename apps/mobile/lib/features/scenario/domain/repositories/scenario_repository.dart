/// Abstract repository interface for scenario data access.
///
/// Implementations:
/// - [MockScenarioRepository] for local development and testing.
/// - [ApiScenarioRepository] backed by the FastAPI backend (Phase 3).
library;

import '../models/response_record.dart';
import '../models/scenario.dart';
import '../models/user_progress.dart';

/// Contract for fetching and submitting daily scenarios.
abstract class ScenarioRepository {
  /// Fetches today's assigned scenario for the current employee.
  ///
  /// Returns `null` if no scenario is assigned today.
  /// Throws on network or server errors.
  Future<Scenario?> getTodayScenario();

  /// Submits the employee's answer for a scenario.
  ///
  /// Returns the [ScenarioResult] with correctness and explanation.
  /// Includes an idempotency key to prevent duplicate submissions.
  Future<ScenarioResult> submitAnswer({
    required String scenarioId,
    required String selectedOptionId,
  });

  /// Fetches the user's response history, most recent first.
  Future<List<ResponseRecord>> getHistory({
    int page = 1,
    int pageSize = 20,
  });

  /// Fetches the user's progress summary.
  Future<UserProgress> getProgress();
}
