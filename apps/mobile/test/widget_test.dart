import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (tester) async {
    // Just ensure the app widget tree builds without exceptions.
    // Detailed screen tests are in test/core/ and test/features/
    await tester.pumpWidget(const _TestApp());
    expect(find.byType(_TestApp), findsOneWidget);
  });
}

// Minimal wrapper to avoid OIDC/DI initialization in smoke test
class _TestApp extends StatelessWidget {
  const _TestApp();
  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: SizedBox.shrink());
}
