import 'package:flutter_test/flutter_test.dart';
import 'package:security_pulse/features/scenario/domain/models/response_record.dart';
import 'package:security_pulse/features/scenario/domain/models/scenario.dart';
import 'package:security_pulse/features/scenario/domain/models/user_progress.dart';

void main() {
  group('Scenario.fromJson', () {
    test('parses valid scenario JSON', () {
      final json = {
        'id': 'scenario-123',
        'title': 'Test Scenario',
        'prompt': 'Test prompt text',
        'category': 'phishing',
        'difficulty': 'intermediate',
        'answer_options': [
          {
            'id': 'opt-1',
            'text': 'Option A',
            'display_order': 0,
          },
          {
            'id': 'opt-2',
            'text': 'Option B',
            'display_order': 1,
          },
        ],
      };

      final scenario = Scenario.fromJson(json);

      expect(scenario.id, equals('scenario-123'));
      expect(scenario.title, equals('Test Scenario'));
      expect(scenario.prompt, equals('Test prompt text'));
      expect(scenario.category, equals('phishing'));
      expect(scenario.difficulty, equals('intermediate'));
      expect(scenario.options, hasLength(2));
      expect(scenario.options[0].text, equals('Option A'));
      expect(scenario.options[1].displayOrder, equals(1));
    });

    test('defaults difficulty to beginner when missing', () {
      final json = {
        'id': 'scenario-123',
        'title': 'Test',
        'prompt': 'Prompt',
        'category': 'phishing',
        'answer_options': <Map<String, dynamic>>[],
      };

      final scenario = Scenario.fromJson(json);
      expect(scenario.difficulty, equals('beginner'));
    });
  });

  group('AnswerOption.fromJson', () {
    test('parses valid option JSON', () {
      final json = {
        'id': 'opt-1',
        'text': 'Test option text',
        'display_order': 2,
      };

      final option = AnswerOption.fromJson(json);

      expect(option.id, equals('opt-1'));
      expect(option.text, equals('Test option text'));
      expect(option.displayOrder, equals(2));
    });

    test('defaults display_order to 0 when missing', () {
      final json = {
        'id': 'opt-1',
        'text': 'Option text',
      };

      final option = AnswerOption.fromJson(json);
      expect(option.displayOrder, equals(0));
    });
  });

  group('ScenarioResult.fromJson', () {
    test('parses valid result JSON', () {
      final json = {
        'scenario_id': 'scenario-123',
        'selected_option_id': 'opt-2',
        'is_correct': true,
        'explanation': 'Good job!',
        'recommended_action': 'Keep it up',
        'answer_options': [
          {
            'id': 'opt-1',
            'text': 'Wrong answer',
            'is_correct': false,
            'display_order': 0,
          },
          {
            'id': 'opt-2',
            'text': 'Right answer',
            'is_correct': true,
            'display_order': 1,
          },
        ],
      };

      final result = ScenarioResult.fromJson(json);

      expect(result.scenarioId, equals('scenario-123'));
      expect(result.selectedOptionId, equals('opt-2'));
      expect(result.correctOptionId, equals('opt-2'));
      expect(result.isCorrect, isTrue);
      expect(result.explanation, equals('Good job!'));
      expect(result.recommendedAction, equals('Keep it up'));
    });

    test('identifies correct option from answer_options', () {
      final json = {
        'scenario_id': 'test',
        'selected_option_id': 'opt-1',
        'is_correct': false,
        'explanation': 'Wrong',
        'recommended_action': 'Try again',
        'answer_options': [
          {
            'id': 'opt-1',
            'text': 'A',
            'is_correct': false,
            'display_order': 0,
          },
          {
            'id': 'opt-3',
            'text': 'C',
            'is_correct': true,
            'display_order': 2,
          },
        ],
      };

      final result = ScenarioResult.fromJson(json);
      expect(result.correctOptionId, equals('opt-3'));
    });
  });

  group('ResponseRecord.fromJson', () {
    test('parses valid response record JSON', () {
      final json = {
        'id': 'resp-1',
        'scenario_id': 'scenario-1',
        'scenario_title': 'Test Scenario',
        'submitted_at': '2026-08-13T10:30:00Z',
        'is_correct': true,
      };

      final record = ResponseRecord.fromJson(json);

      expect(record.id, equals('resp-1'));
      expect(record.scenarioId, equals('scenario-1'));
      expect(record.scenarioTitle, equals('Test Scenario'));
      expect(record.submittedAt.year, equals(2026));
      expect(record.isCorrect, isTrue);
    });

    test('parses incorrect response', () {
      final json = {
        'id': 'resp-2',
        'scenario_id': 'scenario-2',
        'scenario_title': 'Another Scenario',
        'submitted_at': '2026-08-12T15:00:00Z',
        'is_correct': false,
      };

      final record = ResponseRecord.fromJson(json);
      expect(record.isCorrect, isFalse);
    });
  });

  group('UserProgress.fromJson', () {
    test('parses valid progress JSON', () {
      final json = {
        'scenarios_assigned': 10,
        'scenarios_completed': 7,
        'current_streak_days': 3,
      };

      final progress = UserProgress.fromJson(json);

      expect(progress.scenariosAssigned, equals(10));
      expect(progress.scenariosCompleted, equals(7));
      expect(progress.currentStreakDays, equals(3));
    });

    test('parses zero state', () {
      final json = {
        'scenarios_assigned': 0,
        'scenarios_completed': 0,
        'current_streak_days': 0,
      };

      final progress = UserProgress.fromJson(json);

      expect(progress.scenariosAssigned, equals(0));
      expect(progress.scenariosCompleted, equals(0));
      expect(progress.currentStreakDays, equals(0));
    });
  });
}
