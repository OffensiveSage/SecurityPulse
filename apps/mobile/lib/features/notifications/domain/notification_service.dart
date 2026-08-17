/// Abstract notification service interface.
///
/// Provides a provider-agnostic abstraction for scheduling daily reminders.
/// Production implementations (e.g., FCM, APNs) implement this interface.
/// The default [LocalNotificationService] uses flutter_local_notifications
/// for local development and testing.
///
/// Notification content is static and non-sensitive:
/// - Title: "Security Pulse"
/// - Body: "Your daily security challenge is ready"
/// No user data, answers, or incident information is included.
library;

/// Abstract interface for notification scheduling.
///
/// Implementations must handle platform-specific setup, permissions,
/// and notification delivery.
abstract class NotificationService {
  /// Initializes the notification subsystem (channels, categories, etc.).
  Future<void> initialize();

  /// Schedules a repeating daily notification at the given local time.
  ///
  /// [hour] and [minute] are in 24-hour local time (default: 09:00).
  Future<void> scheduleDailyReminder({int hour = 9, int minute = 0});

  /// Cancels any scheduled daily reminder.
  Future<void> cancelDailyReminder();

  /// Returns whether notification permission has been granted.
  Future<bool> isPermissionGranted();

  /// Requests notification permission from the user.
  ///
  /// Returns `true` if permission was granted, `false` otherwise.
  Future<bool> requestPermission();
}
