import 'package:flutter_test/flutter_test.dart';
import 'package:security_pulse/core/error/failures.dart';
import 'package:security_pulse/core/storage/widget_state_mapper.dart';
import 'package:security_pulse/features/scenario/domain/models/scenario.dart';
import 'package:security_pulse/features/scenario/presentation/providers/daily_scenario_state.dart';

void main() {
  const testScenario = Scenario(
    id: 'scenario-1',
    title: 'Phishing Quiz',
    prompt: 'What should you do?',
    category: 'Phishing',
    options: [
      AnswerOption(id: 'a', text: 'Click the link'),
      AnswerOption(id: 'b', text: 'Report it'),
    ],
  );

  const testResult = ScenarioResult(
    scenarioId: 'scenario-1',
    selectedOptionId: 'b',
    correctOptionId: 'b',
    isCorrect: true,
    explanation: 'Always report suspicious emails.',
    recommendedAction: 'Forward to security team.',
  );

  group('mapScenarioState', () {
    test('maps DailyScenarioLoading to available with /today deep link', () {
      final model = mapScenarioState(const DailyScenarioLoading());

      expect(model.completionState, 'available');
      expect(model.deepLinkRoute, '/today');
      expect(model.title, 'Security Pulse');
      expect(model.expiresAt, isNotNull);
    });

    test('maps DailyScenarioEmpty to no_assignment', () {
      final model = mapScenarioState(const DailyScenarioEmpty());

      expect(model.completionState, 'no_assignment');
      expect(model.deepLinkRoute, isNull);
    });

    test('maps DailyScenarioLoaded to available with scenario title', () {
      final model = mapScenarioState(
        const DailyScenarioLoaded(scenario: testScenario),
      );

      expect(model.completionState, 'available');
      expect(model.title, 'Phishing Quiz');
      expect(model.scenarioId, 'scenario-1');
      expect(model.deepLinkRoute, '/today');
    });

    test('maps DailyScenarioSubmitting to available', () {
      final model = mapScenarioState(
        const DailyScenarioSubmitting(
          scenario: testScenario,
          selectedOptionId: 'b',
        ),
      );

      expect(model.completionState, 'available');
      expect(model.deepLinkRoute, '/today');
    });

    test('maps DailyScenarioCompleted to completed with /progress', () {
      final model = mapScenarioState(
        const DailyScenarioCompleted(
          scenario: testScenario,
          result: testResult,
        ),
      );

      expect(model.completionState, 'completed');
      expect(model.deepLinkRoute, '/progress');
      expect(model.title, 'Phishing Quiz');
    });

    test('maps DailyScenarioError to offline', () {
      final model = mapScenarioState(
        const DailyScenarioError(
          failure: ServerFailure(message: 'Server error', statusCode: 500),
        ),
      );

      expect(model.completionState, 'offline');
      expect(model.deepLinkRoute, isNull);
    });

    test('maps DailyScenarioOffline to offline', () {
      final model = mapScenarioState(const DailyScenarioOffline());

      expect(model.completionState, 'offline');
      expect(model.deepLinkRoute, isNull);
    });

    test('expiresAt is approximately 2 hours in the future', () {
      final model = mapScenarioState(const DailyScenarioLoading());
      final expiresAt = DateTime.parse(model.expiresAt!);
      final twoHoursFromNow = DateTime.now().toUtc().add(
            const Duration(hours: 2),
          );

      // Allow 10 seconds of tolerance for test execution time.
      expect(
        expiresAt.difference(twoHoursFromNow).inSeconds.abs(),
        lessThan(10),
      );
    });
  });

  group('mapAuthSignedOut', () {
    test('returns signed_out state with /signin deep link', () {
      final model = mapAuthSignedOut();

      expect(model.completionState, 'signed_out');
      expect(model.deepLinkRoute, '/signin');
      expect(model.scenarioId, isNull);
      expect(model.expiresAt, isNull);
    });

    test('has descriptive title for signed-out state', () {
      final model = mapAuthSignedOut();

      expect(model.title, contains('Sign in'));
    });
  });
}
