/// Riverpod provider for notification preference (enable/disable daily reminder).
///
/// Persists the preference in flutter_secure_storage.
/// Toggles the notification schedule through [NotificationService].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'notification_service_provider.dart';

const _storageKey = 'notification_preference';
const _enabledValue = 'enabled';
const _disabledValue = 'disabled';

/// Provides the [FlutterSecureStorage] instance for notification preferences.
///
/// Override in tests with a mock implementation.
final notificationStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Provides the notification preference state (enabled/disabled).
final notificationPreferenceProvider =
    AsyncNotifierProvider.autoDispose<NotificationPreferenceNotifier, bool>(
  NotificationPreferenceNotifier.new,
);

class NotificationPreferenceNotifier extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final storage = ref.read(notificationStorageProvider);
    final value = await storage.read(key: _storageKey);
    return value == _enabledValue;
  }

  /// Toggles the notification preference.
  ///
  /// When enabling: requests permission and schedules daily reminder.
  /// When disabling: cancels the scheduled reminder.
  Future<void> toggle() async {
    final currentlyEnabled = await future;
    final service = ref.read(notificationServiceProvider);
    final storage = ref.read(notificationStorageProvider);

    if (!currentlyEnabled) {
      // Enabling notifications.
      final granted = await service.requestPermission();
      if (!granted) {
        // Permission denied — stay disabled.
        return;
      }
      await service.scheduleDailyReminder();
      await storage.write(key: _storageKey, value: _enabledValue);
      state = const AsyncData(true);
    } else {
      // Disabling notifications.
      await service.cancelDailyReminder();
      await storage.write(key: _storageKey, value: _disabledValue);
      state = const AsyncData(false);
    }
  }
}
