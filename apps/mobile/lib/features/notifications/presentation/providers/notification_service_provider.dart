/// Riverpod provider for the notification service.
///
/// Defaults to [LocalNotificationService] for local development.
/// Override with a push notification implementation (FCM/APNs) for production.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_notification_service.dart';
import '../../domain/notification_service.dart';

/// Provides the [NotificationService] implementation.
///
/// Override in production:
/// ```dart
/// notificationServiceProvider.overrideWithValue(FcmNotificationService())
/// ```
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});
