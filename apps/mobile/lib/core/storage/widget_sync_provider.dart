/// Provider that automatically syncs widget state when scenario or auth changes.
///
/// Listens to both [dailyScenarioProvider] and [authProvider], mapping state
/// changes to [DailyCardBridgeModel] and writing through the [WidgetBridge].
///
/// Initialized by watching this provider in [SecurityPulseApp.build()].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/scenario/presentation/providers/daily_scenario_provider.dart';
import 'widget_bridge_provider.dart';
import 'widget_state_mapper.dart';

/// A provider that sets up listeners to sync widget state.
///
/// Watch this provider in the app root to activate the listeners.
final widgetSyncProvider = Provider<void>((ref) {
  final bridge = ref.read(widgetBridgeProvider);

  // Listen to auth state changes.
  ref.listen(authProvider, (previous, next) {
    if (next is AuthUnauthenticated ||
        next is AuthInitial ||
        next is AuthError) {
      bridge.updateWidget(mapAuthSignedOut());
    }
  });

  // Listen to scenario state changes.
  ref.listen(dailyScenarioProvider, (previous, next) {
    // Only update widget when user is authenticated (auth listener handles sign-out).
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      bridge.updateWidget(mapScenarioState(next));
    }
  });
});
