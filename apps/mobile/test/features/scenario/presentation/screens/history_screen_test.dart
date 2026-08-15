import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:security_pulse/core/error/failures.dart';
import 'package:security_pulse/core/l10n/app_localizations.dart';
import 'package:security_pulse/features/scenario/domain/models/response_record.dart';
import 'package:security_pulse/features/scenario/domain/repositories/scenario_repository.dart';
import 'package:security_pulse/features/scenario/presentation/providers/daily_scenario_provider.dart';
import 'package:security_pulse/features/scenario/presentation/providers/history_provider.dart';
import 'package:security_pulse/features/scenario/presentation/screens/history_screen.dart';

class _MockScenarioRepository extends Mock implements ScenarioRepository {}

/// A notifier that returns a fixed state without loading from a repository.
class _FixedHistoryNotifier extends HistoryNotifier {
  _FixedHistoryNotifier(this._fixedState);
  final HistoryState _fixedState;

  @override
  HistoryState build() => _fixedState;
}

Widget _buildWithFixedState(HistoryState state) {
  return ProviderScope(
    overrides: [
      historyProvider.overrideWith(() => _FixedHistoryNotifier(state)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HistoryScreen(),
    ),
  );
}

Widget _buildWithMockRepo(_MockScenarioRepository mockRepo) {
  return ProviderScope(
    overrides: [
      scenarioRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HistoryScreen(),
    ),
  );
}

void main() {
  group('HistoryScreen', () {
    testWidgets('shows loading indicator in loading state', (tester) async {
      await tester.pumpWidget(_buildWithFixedState(const HistoryLoading()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty view when no records', (tester) async {
      await tester.pumpWidget(_buildWithFixedState(const HistoryEmpty()));
      await tester.pumpAndSettle();

      expect(find.text('No activity yet'), findsOneWidget);
      expect(
        find.text('Your completed questions will appear here.'),
        findsOneWidget,
      );
    });

    testWidgets('shows list items when records exist', (tester) async {
      final state = HistoryLoaded(
        records: [
          ResponseRecord(
            id: 'resp-1',
            scenarioId: 'scenario-1',
            scenarioTitle: 'Phishing Email Test',
            submittedAt: DateTime(2026, 8, 13),
            isCorrect: true,
          ),
          ResponseRecord(
            id: 'resp-2',
            scenarioId: 'scenario-2',
            scenarioTitle: 'MFA Fatigue Attack',
            submittedAt: DateTime(2026, 8, 12),
            isCorrect: false,
          ),
        ],
      );
      await tester.pumpWidget(_buildWithFixedState(state));
      await tester.pumpAndSettle();

      expect(find.text('Phishing Email Test'), findsOneWidget);
      expect(find.text('MFA Fatigue Attack'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    });

    testWidgets('shows error view with retry button on failure',
        (tester) async {
      const state = HistoryError(
        failure: ServerFailure(
          message: 'Server error',
          statusCode: 500,
        ),
      );
      await tester.pumpWidget(_buildWithFixedState(state));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('loads from mock repository and shows empty', (tester) async {
      final mockRepo = _MockScenarioRepository();
      when(
        () => mockRepo.getHistory(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildWithMockRepo(mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('No activity yet'), findsOneWidget);
    });
  });
}
