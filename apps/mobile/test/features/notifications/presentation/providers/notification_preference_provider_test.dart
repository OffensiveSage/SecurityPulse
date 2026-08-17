import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:security_pulse/features/notifications/data/mock_notification_service.dart';
import 'package:security_pulse/features/notifications/presentation/providers/notification_preference_provider.dart';
import 'package:security_pulse/features/notifications/presentation/providers/notification_service_provider.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockNotificationService mockService;
  late _MockSecureStorage mockStorage;
  late ProviderContainer container;

  setUp(() {
    mockService = MockNotificationService();
    mockStorage = _MockSecureStorage();

    // Default: no stored value (notifications disabled).
    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(
      () => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer() {
    container = ProviderContainer(
      overrides: [
        notificationServiceProvider.overrideWithValue(mockService),
        notificationStorageProvider.overrideWithValue(mockStorage),
      ],
    );
    return container;
  }

  group('NotificationPreferenceNotifier', () {
    test('initial state is false (disabled)', () async {
      final c = createContainer();
      await c.read(notificationPreferenceProvider.future);

      final value = c.read(notificationPreferenceProvider).value;
      expect(value, isFalse);
    });

    test('toggle enables notifications and schedules reminder', () async {
      final c = createContainer();
      await c.read(notificationPreferenceProvider.future);

      await c.read(notificationPreferenceProvider.notifier).toggle();

      expect(mockService.scheduled, isTrue);
      expect(c.read(notificationPreferenceProvider).value, isTrue);
      verify(
        () => mockStorage.write(key: any(named: 'key'), value: 'enabled'),
      ).called(1);
    });

    test('toggle disables notifications and cancels reminder', () async {
      // Start with enabled state.
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'enabled');

      final c = createContainer();
      await c.read(notificationPreferenceProvider.future);
      expect(c.read(notificationPreferenceProvider).value, isTrue);

      await c.read(notificationPreferenceProvider.notifier).toggle();

      expect(mockService.scheduled, isFalse);
      expect(c.read(notificationPreferenceProvider).value, isFalse);
      verify(
        () => mockStorage.write(key: any(named: 'key'), value: 'disabled'),
      ).called(1);
    });

    test('toggle does not enable when permission denied', () async {
      mockService.permissionGranted = false;
      final c = createContainer();
      await c.read(notificationPreferenceProvider.future);

      await c.read(notificationPreferenceProvider.notifier).toggle();

      expect(mockService.scheduled, isFalse);
      expect(c.read(notificationPreferenceProvider).value, isFalse);
    });
  });
}
