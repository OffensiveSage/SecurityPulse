import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:security_pulse/core/error/failures.dart';
import 'package:security_pulse/core/l10n/app_localizations.dart';
import 'package:security_pulse/core/widgets/error_view.dart';

/// Helper that wraps a widget in a MaterialApp with the app's localization
/// delegates, matching the real app setup in app.dart.
Widget _localized(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('ErrorView', () {
    testWidgets('renders server failure message', (tester) async {
      await tester.pumpWidget(
        _localized(
          const ErrorView(
            failure: ServerFailure(
              message: 'Service unavailable',
              statusCode: 503,
            ),
          ),
        ),
      );
      expect(find.text('Service unavailable'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _localized(
          ErrorView(
            failure: const NetworkFailure(),
            onRetry: () => retried = true,
          ),
        ),
      );
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });

    testWidgets('shows network-specific title for NetworkFailure',
        (tester) async {
      await tester.pumpWidget(
        _localized(const ErrorView(failure: NetworkFailure())),
      );
      expect(find.text('No connection'), findsOneWidget);
    });

    testWidgets('shows unauthorized title for UnauthorizedFailure',
        (tester) async {
      await tester.pumpWidget(
        _localized(const ErrorView(failure: UnauthorizedFailure())),
      );
      expect(find.text('Access denied'), findsOneWidget);
    });

    testWidgets('has live region semantics', (tester) async {
      await tester.pumpWidget(
        _localized(const ErrorView(failure: NetworkFailure())),
      );
      final semantics = tester.getSemantics(find.byType(ErrorView));
      expect(semantics.flagsCollection.isLiveRegion, isTrue);
    });
  });
}
