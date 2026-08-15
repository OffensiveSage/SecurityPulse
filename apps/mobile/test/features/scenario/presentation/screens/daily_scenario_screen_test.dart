import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:security_pulse/core/error/failures.dart';
import 'package:security_pulse/core/l10n/app_localizations.dart';
import 'package:security_pulse/core/widgets/empty_view.dart';
import 'package:security_pulse/core/widgets/error_view.dart';
import 'package:security_pulse/core/widgets/loading_view.dart';
import 'package:security_pulse/features/scenario/domain/models/scenario.dart';
import 'package:security_pulse/features/scenario/domain/repositories/scenario_repository.dart';
import 'package:security_pulse/features/scenario/presentation/providers/daily_scenario_provider.dart';
import 'package:security_pulse/features/scenario/presentation/providers/daily_scenario_state.dart';
import 'package:security_pulse/features/scenario/presentation/screens/daily_scenario_screen.dart';
import 'package:security_pulse/features/scenario/presentation/widgets/answer_option_tile.dart';

class _MockScenarioRepository extends Mock implements ScenarioRepository {}

const _testScenario = Scenario(
  id: 'test-1',
  title: 'Test Scenario',
  prompt: 'You received a suspicious email asking for credentials.',
  category: 'Phishing',
  options: [
    AnswerOption(id: 'opt-1', text: 'Click the link'),
    AnswerOption(id: 'opt-2', text: 'Report to security team'),
    AnswerOption(id: 'opt-3', text: 'Reply to sender'),
  ],
);

const _correctResult = ScenarioResult(
  scenarioId: 'test-1',
  selectedOptionId: 'opt-2',
  correctOptionId: 'opt-2',
  isCorrect: true,
  explanation: 'Reporting suspicious emails protects everyone.',
  recommendedAction: 'Always report and delete suspicious emails.',
);

const _incorrectResult = ScenarioResult(
  scenarioId: 'test-1',
  selectedOptionId: 'opt-1',
  correctOptionId: 'opt-2',
  isCorrect: false,
  explanation: 'Never click suspicious links.',
  recommendedAction: 'Report to security team instead.',
);

/// Builds a test app with the [DailyScenarioScreen] pinned to a fixed state.
Widget _buildWithFixedState(DailyScenarioState state) {
  return ProviderScope(
    overrides: [
      dailyScenarioProvider.overrideWith(() => _FixedNotifier(state)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DailyScenarioScreen(),
    ),
  );
}

/// Builds a test app with a mock repository for interaction testing.
Widget _buildWithMockRepo(_MockScenarioRepository mockRepo) {
  return ProviderScope(
    overrides: [
      scenarioRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DailyScenarioScreen(),
    ),
  );
}

/// A notifier that returns a fixed state without loading from a repository.
class _FixedNotifier extends DailyScenarioNotifier {
  _FixedNotifier(this._fixedState);
  final DailyScenarioState _fixedState;

  @override
  DailyScenarioState build() => _fixedState;
}

void main() {
  group('DailyScenarioScreen', () {
    group('loading state', () {
      testWidgets('shows loading indicator', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const DailyScenarioLoading()),
        );
        await tester.pump();

        expect(find.byType(LoadingView), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows loading message', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const DailyScenarioLoading()),
        );
        await tester.pump();

        expect(find.textContaining('Loading'), findsOneWidget);
      });
    });

    group('empty state', () {
      testWidgets('shows empty view', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const DailyScenarioEmpty()),
        );
        await tester.pump();

        expect(find.byType(EmptyView), findsOneWidget);
      });

      testWidgets('shows correct empty message', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const DailyScenarioEmpty()),
        );
        await tester.pump();

        expect(find.text('No question today'), findsOneWidget);
        expect(
          find.text('Check back later for your next security question.'),
          findsOneWidget,
        );
      });
    });

    group('error state', () {
      testWidgets('shows error view', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioError(
              failure: ServerFailure(message: 'Server error', statusCode: 500),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ErrorView), findsOneWidget);
      });

      testWidgets('shows retry button', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioError(
              failure: ServerFailure(message: 'Server error', statusCode: 500),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Try again'), findsOneWidget);
      });
    });

    group('offline state', () {
      testWidgets('shows offline view with no connection title',
          (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const DailyScenarioOffline()),
        );
        await tester.pump();

        expect(find.text('No connection'), findsOneWidget);
      });

      testWidgets('shows retry button', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const DailyScenarioOffline()),
        );
        await tester.pump();

        expect(find.text('Try again'), findsOneWidget);
      });
    });

    group('loaded state', () {
      testWidgets('shows scenario prompt', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioLoaded(scenario: _testScenario),
          ),
        );
        await tester.pump();

        expect(find.text(_testScenario.prompt), findsOneWidget);
      });

      testWidgets('shows category chip', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioLoaded(scenario: _testScenario),
          ),
        );
        await tester.pump();

        expect(find.text('Phishing'), findsOneWidget);
      });

      testWidgets('shows daily challenge heading', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioLoaded(scenario: _testScenario),
          ),
        );
        await tester.pump();

        expect(find.text('Daily Security Challenge'), findsOneWidget);
      });

      testWidgets('shows all answer options', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioLoaded(scenario: _testScenario),
          ),
        );
        await tester.pump();

        expect(find.byType(AnswerOptionTile), findsNWidgets(3));
        expect(find.text('Click the link'), findsOneWidget);
        expect(find.text('Report to security team'), findsOneWidget);
        expect(find.text('Reply to sender'), findsOneWidget);
      });

      testWidgets('shows submit button', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioLoaded(scenario: _testScenario),
          ),
        );
        await tester.pump();

        expect(find.text('Submit answer'), findsOneWidget);
      });

      testWidgets('submit button is disabled without selection',
          (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioLoaded(scenario: _testScenario),
          ),
        );
        await tester.pump();

        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Submit answer'),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('submit button is enabled with selection', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioLoaded(
              scenario: _testScenario,
              selectedOptionId: 'opt-2',
            ),
          ),
        );
        await tester.pump();

        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Submit answer'),
        );
        expect(button.onPressed, isNotNull);
      });

      testWidgets('shows Security Pulse in app bar', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioLoaded(scenario: _testScenario),
          ),
        );
        await tester.pump();

        expect(find.text('Security Pulse'), findsOneWidget);
      });
    });

    group('submitting state', () {
      testWidgets('shows loading indicator', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioSubmitting(
              scenario: _testScenario,
              selectedOptionId: 'opt-2',
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(LoadingView), findsOneWidget);
      });
    });

    group('completed state — correct answer', () {
      testWidgets('shows correct banner', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioCompleted(
              scenario: _testScenario,
              result: _correctResult,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Correct!'), findsOneWidget);
      });

      testWidgets('shows explanation', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioCompleted(
              scenario: _testScenario,
              result: _correctResult,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Why this matters'), findsOneWidget);
        expect(find.text(_correctResult.explanation), findsOneWidget);
      });

      testWidgets('shows recommended action', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioCompleted(
              scenario: _testScenario,
              result: _correctResult,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('What you should do'), findsOneWidget);
        expect(find.text(_correctResult.recommendedAction), findsOneWidget);
      });

      testWidgets('shows completion banner', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioCompleted(
              scenario: _testScenario,
              result: _correctResult,
            ),
          ),
        );
        await tester.pump();

        expect(
          find.textContaining('challenge completed'),
          findsOneWidget,
        );
      });
    });

    group('completed state — incorrect answer', () {
      testWidgets('shows incorrect banner', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            const DailyScenarioCompleted(
              scenario: _testScenario,
              result: _incorrectResult,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Not quite right'), findsOneWidget);
      });
    });

    group('full question flow', () {
      testWidgets('load → select → submit → result', (tester) async {
        final mockRepo = _MockScenarioRepository();
        when(mockRepo.getTodayScenario).thenAnswer((_) async => _testScenario);
        when(
          () => mockRepo.submitAnswer(
            scenarioId: any(named: 'scenarioId'),
            selectedOptionId: any(named: 'selectedOptionId'),
          ),
        ).thenAnswer((_) async => _correctResult);

        await tester.pumpWidget(_buildWithMockRepo(mockRepo));

        // Loading state
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for scenario to load
        await tester.pumpAndSettle();

        // Verify loaded state
        expect(find.text(_testScenario.prompt), findsOneWidget);
        expect(find.text('Submit answer'), findsOneWidget);

        // Select an answer
        await tester.tap(find.text('Report to security team'));
        await tester.pumpAndSettle();

        // Submit
        await tester.tap(find.text('Submit answer'));
        await tester.pumpAndSettle();

        // Verify result
        expect(find.text('Correct!'), findsOneWidget);
        expect(find.text(_correctResult.explanation), findsOneWidget);
        expect(find.text(_correctResult.recommendedAction), findsOneWidget);
        expect(find.textContaining('challenge completed'), findsOneWidget);
      });

      testWidgets('shows incorrect result for wrong answer', (tester) async {
        final mockRepo = _MockScenarioRepository();
        when(mockRepo.getTodayScenario).thenAnswer((_) async => _testScenario);
        when(
          () => mockRepo.submitAnswer(
            scenarioId: any(named: 'scenarioId'),
            selectedOptionId: any(named: 'selectedOptionId'),
          ),
        ).thenAnswer((_) async => _incorrectResult);

        await tester.pumpWidget(_buildWithMockRepo(mockRepo));
        await tester.pumpAndSettle();

        // Select wrong answer and submit
        await tester.tap(find.text('Click the link'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Submit answer'));
        await tester.pumpAndSettle();

        expect(find.text('Not quite right'), findsOneWidget);
      });
    });
  });
}
