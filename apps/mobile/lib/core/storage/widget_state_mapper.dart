/// Maps application state to the DailyCardBridgeModel for widget display.
///
/// Pure functions that convert [DailyScenarioState] and auth state into
/// the bridge model consumed by native widgets. No side effects.
library;

import '../../features/scenario/presentation/providers/daily_scenario_state.dart';
import 'daily_card_bridge.dart';

/// Default widget title when no scenario title is available.
const _defaultTitle = 'Security Pulse';

/// Default expiry window from now (2 hours).
const _expiryDuration = Duration(hours: 2);

/// Maps a [DailyScenarioState] to a [DailyCardBridgeModel].
DailyCardBridgeModel mapScenarioState(DailyScenarioState state) {
  final expiresAt =
      DateTime.now().add(_expiryDuration).toUtc().toIso8601String();

  return switch (state) {
    DailyScenarioLoading() => DailyCardBridgeModel(
        title: _defaultTitle,
        completionState: 'available',
        deepLinkRoute: '/today',
        expiresAt: expiresAt,
      ),
    DailyScenarioEmpty() => DailyCardBridgeModel(
        title: _defaultTitle,
        completionState: 'no_assignment',
        expiresAt: expiresAt,
      ),
    DailyScenarioLoaded(:final scenario) => DailyCardBridgeModel(
        scenarioId: scenario.id,
        title: scenario.title,
        completionState: 'available',
        deepLinkRoute: '/today',
        expiresAt: expiresAt,
      ),
    DailyScenarioSubmitting(:final scenario) => DailyCardBridgeModel(
        scenarioId: scenario.id,
        title: scenario.title,
        completionState: 'available',
        deepLinkRoute: '/today',
        expiresAt: expiresAt,
      ),
    DailyScenarioCompleted(:final scenario) => DailyCardBridgeModel(
        scenarioId: scenario.id,
        title: scenario.title,
        completionState: 'completed',
        deepLinkRoute: '/progress',
        expiresAt: expiresAt,
      ),
    DailyScenarioError() => DailyCardBridgeModel(
        title: _defaultTitle,
        completionState: 'offline',
        expiresAt: expiresAt,
      ),
    DailyScenarioOffline() => DailyCardBridgeModel(
        title: _defaultTitle,
        completionState: 'offline',
        expiresAt: expiresAt,
      ),
  };
}

/// Returns a bridge model for the signed-out state.
DailyCardBridgeModel mapAuthSignedOut() {
  return const DailyCardBridgeModel(
    title: 'Sign in to see today\u2019s question',
    completionState: 'signed_out',
    deepLinkRoute: '/signin',
  );
}
