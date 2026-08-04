import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:security_pulse/core/error/failures.dart';
import 'package:security_pulse/core/widgets/error_view.dart';

void main() {
  group('ErrorView', () {
    testWidgets('renders server failure message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(
              failure: ServerFailure(
                message: 'Service unavailable',
                statusCode: 503,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Service unavailable'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              failure: const NetworkFailure(),
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });

    testWidgets('shows network-specific title for NetworkFailure',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorView(failure: NetworkFailure())),
        ),
      );
      expect(find.text('No connection'), findsOneWidget);
    });

    testWidgets('shows unauthorized title for UnauthorizedFailure',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorView(failure: UnauthorizedFailure())),
        ),
      );
      expect(find.text('Access denied'), findsOneWidget);
    });

    testWidgets('has live region semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorView(failure: NetworkFailure())),
        ),
      );
      final semantics = tester.getSemantics(find.byType(ErrorView));
      expect(semantics.flagsCollection.isLiveRegion, isTrue);
    });
  });
}
