/// Mock implementation of [ScenarioRepository] for local development.
///
/// Returns a hardcoded phishing scenario with a simulated network delay.
/// Used in tests and development when no backend is available.
library;

import '../../domain/models/response_record.dart';
import '../../domain/models/scenario.dart';
import '../../domain/models/user_progress.dart';
import '../../domain/repositories/scenario_repository.dart';

class MockScenarioRepository implements ScenarioRepository {
  static const _correctOptionId = 'opt-2';

  static const _mockScenario = Scenario(
    id: 'scenario-2026-08-12',
    title: 'Suspicious Email from IT Support',
    prompt: 'You receive an email from "IT-Support@yourcompany.co" asking you '
        'to verify your credentials by clicking a link due to a "mandatory '
        'security upgrade." The email includes your company\'s logo and '
        'threatens account suspension if you don\'t act within 24 hours.',
    category: 'Phishing',
    options: [
      AnswerOption(
        id: 'opt-1',
        text: 'Click the link and enter your credentials to avoid '
            'losing access',
      ),
      AnswerOption(
        id: 'opt-2',
        text: 'Forward the email to the security team and delete it',
        displayOrder: 1,
      ),
      AnswerOption(
        id: 'opt-3',
        text: 'Reply to the sender asking if the email is legitimate',
        displayOrder: 2,
      ),
      AnswerOption(
        id: 'opt-4',
        text: 'Ignore the email and do nothing',
        displayOrder: 3,
      ),
    ],
  );

  @override
  Future<Scenario?> getTodayScenario() async {
    // Simulate network latency.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return _mockScenario;
  }

  @override
  Future<ScenarioResult> submitAnswer({
    required String scenarioId,
    required String selectedOptionId,
  }) async {
    // Simulate network latency.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    return ScenarioResult(
      scenarioId: scenarioId,
      selectedOptionId: selectedOptionId,
      correctOptionId: _correctOptionId,
      isCorrect: selectedOptionId == _correctOptionId,
      explanation: 'This email shows several classic phishing indicators: a '
          'slightly misspelled domain (.co instead of .com), urgency tactics '
          'threatening account suspension, and a request to enter credentials '
          'through an email link. Legitimate IT departments do not ask '
          'employees to verify passwords through email links.',
      recommendedAction: 'Report suspicious emails to your security team '
          'using the designated reporting process. Never click links in '
          'unexpected emails asking for credentials. When in doubt, contact '
          'IT through a known, trusted channel such as your company directory '
          'or IT service portal.',
    );
  }

  @override
  Future<List<ResponseRecord>> getHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return [];
  }

  @override
  Future<UserProgress> getProgress() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const UserProgress(
      scenariosAssigned: 0,
      scenariosCompleted: 0,
      currentStreakDays: 0,
    );
  }
}
