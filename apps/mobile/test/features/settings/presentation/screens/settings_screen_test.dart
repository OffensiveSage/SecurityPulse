import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:security_pulse/core/l10n/app_localizations.dart';
import 'package:security_pulse/features/notifications/data/mock_notification_service.dart';
import 'package:security_pulse/features/notifications/presentation/providers/notification_preference_provider.dart';
import 'package:security_pulse/features/notifications/presentation/providers/notification_service_provider.dart';
import 'package:security_pulse/features/settings/presentation/screens/settings_shell_screen.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

Widget _buildTestWidget({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en')],
      home: SettingsShellScreen(),
    ),
  );
}

void main() {
  late _MockSecureStorage mockStorage;

  setUp(() {
    mockStorage = _MockSecureStorage();
    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(
      () => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
  });

  List<Override> defaultOverrides() => [
        notificationServiceProvider
            .overrideWithValue(MockNotificationService()),
        notificationStorageProvider.overrideWithValue(mockStorage),
      ];

  group('SettingsShellScreen', () {
    testWidgets('renders notification toggle', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(overrides: defaultOverrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily reminder'), findsOneWidget);
      expect(
        find.text(
          'Get a daily notification when your security challenge is ready',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders settings screen title', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(overrides: defaultOverrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('toggle can be tapped', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(overrides: defaultOverrides()),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
    });
  });
}
