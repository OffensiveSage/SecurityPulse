import 'package:flutter_test/flutter_test.dart';
import 'package:security_pulse/features/scenario/domain/models/user_progress.dart';

void main() {
  group('UserProgress', () {
    test('fromJson parses all fields including campaignEligible', () {
      final json = {
        'scenarios_assigned': 10,
        'scenarios_completed': 7,
        'current_streak_days': 3,
        'campaign_eligible': true,
      };
      final progress = UserProgress.fromJson(json);
      expect(progress.scenariosAssigned, 10);
      expect(progress.scenariosCompleted, 7);
      expect(progress.currentStreakDays, 3);
      expect(progress.campaignEligible, isTrue);
    });

    test('fromJson handles null campaign_eligible', () {
      final json = {
        'scenarios_assigned': 5,
        'scenarios_completed': 2,
        'current_streak_days': 1,
      };
      final progress = UserProgress.fromJson(json);
      expect(progress.campaignEligible, isNull);
    });

    test('fromJson handles false campaign_eligible', () {
      final json = {
        'scenarios_assigned': 5,
        'scenarios_completed': 2,
        'current_streak_days': 0,
        'campaign_eligible': false,
      };
      final progress = UserProgress.fromJson(json);
      expect(progress.campaignEligible, isFalse);
    });
  });
}
