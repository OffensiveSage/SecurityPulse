/// Riverpod provider for the widget bridge.
///
/// Defaults to [PlatformWidgetBridge] which uses a MethodChannel
/// to write DailyCardModel to platform-specific shared storage.
/// Override in tests with [NoOpWidgetBridge].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'daily_card_bridge.dart';

/// Provides the [WidgetBridge] implementation.
///
/// Override in tests:
/// ```dart
/// final container = ProviderContainer(
///   overrides: [widgetBridgeProvider.overrideWithValue(NoOpWidgetBridge())],
/// );
/// ```
final widgetBridgeProvider = Provider<WidgetBridge>((ref) {
  return PlatformWidgetBridge();
});
