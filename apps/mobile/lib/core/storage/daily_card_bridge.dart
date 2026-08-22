/// Widget bridge for writing DailyCardModel to platform-specific shared storage.
///
/// Android: SharedPreferences("security_pulse_widget") key "daily_card_model"
/// iOS: UserDefaults(suiteName: "group.com.securitypulse.shared") key "daily_card_model"
///
/// The native widgets (Jetpack Glance / WidgetKit) read from these stores.
/// This bridge writes the minimal, non-sensitive DailyCardModel JSON.
///
/// IMPORTANT: Never include auth tokens, answer correctness, PII, or incident
/// data in this model. See SECURITY.md and THREAT_MODEL.md.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Minimal model written to shared storage for native widget consumption.
///
/// Fields match the JSON schema expected by:
/// - `DailyCardModel.kt` (Android)
/// - `DailyCardModel.swift` (iOS)
class DailyCardBridgeModel {
  const DailyCardBridgeModel({
    required this.title,
    required this.completionState,
    this.scenarioId,
    this.deepLinkRoute,
    this.expiresAt,
  });

  /// The scenario UUID, if applicable.
  final String? scenarioId;

  /// Short title displayed on the widget (max 80 chars).
  final String title;

  /// One of: "available", "completed", "no_assignment", "offline", "signed_out".
  final String completionState;

  /// Deep link route path (e.g., "/today", "/progress", "/signin").
  final String? deepLinkRoute;

  /// ISO 8601 UTC timestamp after which the widget should show "offline" state.
  final String? expiresAt;

  /// Serializes to the JSON format consumed by native widget code.
  Map<String, dynamic> toJson() => {
        'scenarioId': scenarioId ?? '',
        'title': title,
        'completionState': completionState,
        'deepLinkRoute': deepLinkRoute ?? '',
        'expiresAt': expiresAt ?? '',
      };
}

/// Abstract interface for writing widget data to platform-specific storage.
abstract class WidgetBridge {
  /// Writes the model to shared storage and triggers a widget refresh.
  Future<void> updateWidget(DailyCardBridgeModel model);

  /// Clears the widget data from shared storage and triggers a widget refresh.
  Future<void> clearWidget();
}

/// Production implementation using a MethodChannel to native platform code.
///
/// Android: writes to SharedPreferences, triggers AppWidget update.
/// iOS: writes to App Group UserDefaults, triggers WidgetCenter reload.
class PlatformWidgetBridge implements WidgetBridge {
  PlatformWidgetBridge({MethodChannel? channel})
      : _channel =
            channel ?? const MethodChannel('com.securitypulse/widget_bridge');

  final MethodChannel _channel;

  @override
  Future<void> updateWidget(DailyCardBridgeModel model) async {
    if (kIsWeb) return; // Platform channels are not available on web.
    try {
      final jsonString = jsonEncode(model.toJson());
      await _channel.invokeMethod<void>('updateDailyCard', jsonString);
    } on PlatformException {
      // Widget update is best-effort. Failure should not crash the app.
    }
  }

  @override
  Future<void> clearWidget() async {
    if (kIsWeb) return; // Platform channels are not available on web.
    try {
      await _channel.invokeMethod<void>('clearDailyCard');
    } on PlatformException {
      // Best-effort.
    }
  }
}

/// No-op implementation for testing. Records calls for verification.
class NoOpWidgetBridge implements WidgetBridge {
  final List<DailyCardBridgeModel> updates = [];
  int clearCount = 0;

  @override
  Future<void> updateWidget(DailyCardBridgeModel model) async {
    updates.add(model);
  }

  @override
  Future<void> clearWidget() async {
    clearCount++;
  }
}
