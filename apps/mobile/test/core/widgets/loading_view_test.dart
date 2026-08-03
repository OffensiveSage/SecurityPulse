import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:security_pulse/core/widgets/loading_view.dart';

void main() {
  group('LoadingView', () {
    testWidgets('renders without message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingView())),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders with message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingView(message: 'Loading scenarios…')),
        ),
      );
      expect(find.text('Loading scenarios…'), findsOneWidget);
    });

    testWidgets('has live region semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingView(message: 'Loading…')),
        ),
      );
      final semantics = tester.getSemantics(find.byType(LoadingView));
      expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
    });
  });
}
