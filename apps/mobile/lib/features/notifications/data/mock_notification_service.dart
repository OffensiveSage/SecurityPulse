/// No-op notification service for testing.
///
/// Records method calls for verification in tests.
library;

import '../domain/notification_service.dart';

class MockNotificationService implements NotificationService {
  bool initialized = false;
  bool scheduled = false;
  int scheduledHour = 0;
  int scheduledMinute = 0;
  bool permissionGranted = true;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> scheduleDailyReminder({int hour = 9, int minute = 0}) async {
    scheduled = true;
    scheduledHour = hour;
    scheduledMinute = minute;
  }

  @override
  Future<void> cancelDailyReminder() async {
    scheduled = false;
  }

  @override
  Future<bool> isPermissionGranted() async => permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;
}
