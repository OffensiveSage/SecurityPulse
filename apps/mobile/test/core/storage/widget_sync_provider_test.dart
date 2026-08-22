import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:security_pulse/core/storage/daily_card_bridge.dart';
import 'package:security_pulse/core/storage/widget_bridge_provider.dart';
import 'package:security_pulse/core/storage/widget_sync_provider.dart';
import 'package:security_pulse/features/auth/domain/models/user.dart';
import 'package:security_pulse/features/auth/presentation/providers/auth_provider.dart';
import 'package:security_pulse/features/auth/presentation/providers/auth_state.dart';
import 'package:security_pulse/features/scenario/domain/models/scenario.dart';
import 'package:security_pulse/features/scenario/presentation/providers/daily_scenario_provider.dart';
import 'package:security_pulse/features/scenario/presentation/providers/daily_scenario_state.dart';

const _testScenario = Scenario(
  id: 'scenario-1',
  title: 'Test Scenario',
  prompt: 'What should you do?',
  category: 'Phishing',
  options: [
    AnswerOption(id: 'a', text: 'Option A'),
    AnswerOption(id: 'b', text: 'Option B'),
  ],
);

void main() {
  group('widgetSyncProvider', () {
    test('updates widget when scenario state changes to completed', () {
      final bridge = NoOpWidgetBridge();

      // Use a simple Notifier to drive state changes.
      final scenarioNotifier = _TestScenarioNotifier();
      final authNotifier = _TestAuthNotifier();

      final container = ProviderContainer(
        overrides: [
          widgetBridgeProvider.overrideWithValue(bridge),
          dailyScenarioProvider.overrideWith(() => scenarioNotifier),
          authProvider.overrideWith(() => authNotifier),
        ],
      );
      addTearDown(container.dispose);

      // Read the sync provider to activate listeners.
      container.read(widgetSyncProvider);

      // Simulate auth → authenticated.
      authNotifier.setAuthenticated();

      // Simulate scenario → completed.
      scenarioNotifier.setCompleted();

      expect(bridge.updates, isNotEmpty);
      expect(bridge.updates.last.completionState, 'completed');
    });

    test('updates widget to signed_out when auth becomes unauthenticated', () {
      final bridge = NoOpWidgetBridge();
      final scenarioNotifier = _TestScenarioNotifier();
      final authNotifier = _TestAuthNotifier();

      final container = ProviderContainer(
        overrides: [
          widgetBridgeProvider.overrideWithValue(bridge),
          dailyScenarioProvider.overrideWith(() => scenarioNotifier),
          authProvider.overrideWith(() => authNotifier),
        ],
      );
      addTearDown(container.dispose);

      container.read(widgetSyncProvider);

      // Simulate sign-out.
      authNotifier.setUnauthenticated();

      expect(bridge.updates, isNotEmpty);
      expect(bridge.updates.last.completionState, 'signed_out');
      expect(bridge.updates.last.deepLinkRoute, '/signin');
    });

    test('does not update widget for scenario changes when not authenticated',
        () {
      final bridge = NoOpWidgetBridge();
      final scenarioNotifier = _TestScenarioNotifier();
      final authNotifier = _TestAuthNotifier();

      final container = ProviderContainer(
        overrides: [
          widgetBridgeProvider.overrideWithValue(bridge),
          dailyScenarioProvider.overrideWith(() => scenarioNotifier),
          authProvider.overrideWith(() => authNotifier),
        ],
      );
      addTearDown(container.dispose);

      container.read(widgetSyncProvider);

      // Scenario changes while unauthenticated — should not trigger widget update.
      final countBefore = bridge.updates.length;
      scenarioNotifier.setLoaded();

      expect(bridge.updates.length, countBefore);
    });
  });
}

/// Test-only notifier that allows manually setting scenario state.
class _TestScenarioNotifier extends DailyScenarioNotifier {
  @override
  DailyScenarioState build() => const DailyScenarioLoading();

  void setCompleted() {
    state = const DailyScenarioCompleted(
      scenario: _testScenario,
      result: ScenarioResult(
        scenarioId: 'scenario-1',
        selectedOptionId: 'b',
        correctOptionId: 'b',
        isCorrect: true,
        explanation: 'Correct!',
        recommendedAction: 'Keep it up.',
      ),
    );
  }

  void setLoaded() {
    state = const DailyScenarioLoaded(scenario: _testScenario);
  }
}

/// Test-only notifier that allows manually setting auth state.
class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthInitial();

  void setAuthenticated() {
    state = const AuthAuthenticated(
      user: _testUser,
    );
  }

  void setUnauthenticated() {
    state = const AuthUnauthenticated();
  }
}

const _testUser = User(
  id: 'user-1',
  role: UserRole.employee,
  displayName: 'Test User',
  email: 'test@example.com',
);
