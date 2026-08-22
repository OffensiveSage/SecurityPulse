import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:security_pulse/core/error/failures.dart';
import 'package:security_pulse/features/scenario/domain/models/scenario.dart';
import 'package:security_pulse/features/scenario/domain/repositories/scenario_repository.dart';
import 'package:security_pulse/features/scenario/presentation/providers/daily_scenario_provider.dart';
import 'package:security_pulse/features/scenario/presentation/providers/daily_scenario_state.dart';

class _MockScenarioRepository extends Mock implements ScenarioRepository {}

const _testScenario = Scenario(
  id: 'test-1',
  title: 'Test Scenario',
  prompt: 'Test prompt text',
  category: 'Phishing',
  options: [
    AnswerOption(id: 'opt-a', text: 'Option A'),
    AnswerOption(id: 'opt-b', text: 'Option B'),
    AnswerOption(id: 'opt-c', text: 'Option C'),
  ],
);

const _testResult = ScenarioResult(
  scenarioId: 'test-1',
  selectedOptionId: 'opt-b',
  correctOptionId: 'opt-b',
  isCorrect: true,
  explanation: 'Correct explanation',
  recommendedAction: 'Recommended action text',
);

void main() {
  late _MockScenarioRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = _MockScenarioRepository();
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer() {
    container = ProviderContainer(
      overrides: [
        scenarioRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    return container;
  }

  group('DailyScenarioNotifier', () {
    test('initial state is DailyScenarioLoading', () {
      when(() => mockRepo.getTodayScenario())
          .thenAnswer((_) async => _testScenario);

      final c = createContainer();
      expect(c.read(dailyScenarioProvider), isA<DailyScenarioLoading>());
    });

    test('transitions to DailyScenarioLoaded on successful fetch', () async {
      when(() => mockRepo.getTodayScenario())
          .thenAnswer((_) async => _testScenario);

      final c = createContainer();
      // Trigger build by reading
      c.read(dailyScenarioProvider);

      // Allow async load to complete
      await Future<void>.delayed(Duration.zero);

      final state = c.read(dailyScenarioProvider);
      expect(state, isA<DailyScenarioLoaded>());
      final loaded = state as DailyScenarioLoaded;
      expect(loaded.scenario.id, equals('test-1'));
      expect(loaded.scenario.options, hasLength(3));
      expect(loaded.selectedOptionId, isNull);
    });

    test('transitions to DailyScenarioEmpty when no scenario assigned',
        () async {
      when(() => mockRepo.getTodayScenario()).thenAnswer((_) async => null);

      final c = createContainer();
      c.read(dailyScenarioProvider);
      await Future<void>.delayed(Duration.zero);

      expect(c.read(dailyScenarioProvider), isA<DailyScenarioEmpty>());
    });

    test('transitions to DailyScenarioError on repository exception', () async {
      when(() => mockRepo.getTodayScenario()).thenAnswer((_) async {
        throw Exception('fail');
      });

      final c = createContainer();
      c.read(dailyScenarioProvider);
      await Future<void>.delayed(Duration.zero);

      final state = c.read(dailyScenarioProvider);
      expect(state, isA<DailyScenarioError>());
      expect(
        (state as DailyScenarioError).failure,
        isA<ServerFailure>(),
      );
    });

    group('selectOption', () {
      test('updates selected option in loaded state', () async {
        when(() => mockRepo.getTodayScenario())
            .thenAnswer((_) async => _testScenario);

        final c = createContainer();
        c.read(dailyScenarioProvider);
        await Future<void>.delayed(Duration.zero);

        c.read(dailyScenarioProvider.notifier).selectOption('opt-b');

        final state = c.read(dailyScenarioProvider) as DailyScenarioLoaded;
        expect(state.selectedOptionId, equals('opt-b'));
      });

      test('can change selection', () async {
        when(() => mockRepo.getTodayScenario())
            .thenAnswer((_) async => _testScenario);

        final c = createContainer();
        c.read(dailyScenarioProvider);
        await Future<void>.delayed(Duration.zero);

        c.read(dailyScenarioProvider.notifier).selectOption('opt-a');
        expect(
          (c.read(dailyScenarioProvider) as DailyScenarioLoaded)
              .selectedOptionId,
          equals('opt-a'),
        );

        c.read(dailyScenarioProvider.notifier).selectOption('opt-c');
        expect(
          (c.read(dailyScenarioProvider) as DailyScenarioLoaded)
              .selectedOptionId,
          equals('opt-c'),
        );
      });

      test('does nothing in non-loaded state', () async {
        when(() => mockRepo.getTodayScenario()).thenAnswer((_) async => null);

        final c = createContainer();
        c.read(dailyScenarioProvider);
        await Future<void>.delayed(Duration.zero);

        // State is Empty
        c.read(dailyScenarioProvider.notifier).selectOption('opt-a');
        expect(c.read(dailyScenarioProvider), isA<DailyScenarioEmpty>());
      });
    });

    group('submitAnswer', () {
      test('transitions to completed on successful submission', () async {
        when(() => mockRepo.getTodayScenario())
            .thenAnswer((_) async => _testScenario);
        when(
          () => mockRepo.submitAnswer(
            scenarioId: any(named: 'scenarioId'),
            selectedOptionId: any(named: 'selectedOptionId'),
          ),
        ).thenAnswer((_) async => _testResult);

        final c = createContainer();
        c.read(dailyScenarioProvider);
        await Future<void>.delayed(Duration.zero);

        c.read(dailyScenarioProvider.notifier).selectOption('opt-b');
        await c.read(dailyScenarioProvider.notifier).submitAnswer();

        final state = c.read(dailyScenarioProvider);
        expect(state, isA<DailyScenarioCompleted>());
        final completed = state as DailyScenarioCompleted;
        expect(completed.result.isCorrect, isTrue);
        expect(completed.result.explanation, isNotEmpty);
      });

      test('does nothing without a selected option', () async {
        when(() => mockRepo.getTodayScenario())
            .thenAnswer((_) async => _testScenario);

        final c = createContainer();
        c.read(dailyScenarioProvider);
        await Future<void>.delayed(Duration.zero);

        // No option selected
        await c.read(dailyScenarioProvider.notifier).submitAnswer();

        expect(c.read(dailyScenarioProvider), isA<DailyScenarioLoaded>());
        verifyNever(
          () => mockRepo.submitAnswer(
            scenarioId: any(named: 'scenarioId'),
            selectedOptionId: any(named: 'selectedOptionId'),
          ),
        );
      });

      test('does nothing in non-loaded state', () async {
        when(() => mockRepo.getTodayScenario()).thenAnswer((_) async => null);

        final c = createContainer();
        c.read(dailyScenarioProvider);
        await Future<void>.delayed(Duration.zero);

        await c.read(dailyScenarioProvider.notifier).submitAnswer();

        expect(c.read(dailyScenarioProvider), isA<DailyScenarioEmpty>());
      });

      test('reverts to loaded on submission error', () async {
        when(() => mockRepo.getTodayScenario())
            .thenAnswer((_) async => _testScenario);
        when(
          () => mockRepo.submitAnswer(
            scenarioId: any(named: 'scenarioId'),
            selectedOptionId: any(named: 'selectedOptionId'),
          ),
        ).thenAnswer((_) async {
          throw Exception('submission failed');
        });

        final c = createContainer();
        c.read(dailyScenarioProvider);
        await Future<void>.delayed(Duration.zero);

        c.read(dailyScenarioProvider.notifier).selectOption('opt-a');
        await c.read(dailyScenarioProvider.notifier).submitAnswer();

        final state = c.read(dailyScenarioProvider);
        expect(state, isA<DailyScenarioLoaded>());
        expect(
          (state as DailyScenarioLoaded).selectedOptionId,
          equals('opt-a'),
        );
      });

      test('calls repository with correct arguments', () async {
        when(() => mockRepo.getTodayScenario())
            .thenAnswer((_) async => _testScenario);
        when(
          () => mockRepo.submitAnswer(
            scenarioId: any(named: 'scenarioId'),
            selectedOptionId: any(named: 'selectedOptionId'),
          ),
        ).thenAnswer((_) async => _testResult);

        final c = createContainer();
        c.read(dailyScenarioProvider);
        await Future<void>.delayed(Duration.zero);

        c.read(dailyScenarioProvider.notifier).selectOption('opt-b');
        await c.read(dailyScenarioProvider.notifier).submitAnswer();

        verify(
          () => mockRepo.submitAnswer(
            scenarioId: 'test-1',
            selectedOptionId: 'opt-b',
          ),
        ).called(1);
      });
    });

    group('retry', () {
      test('reloads scenario after error', () async {
        var callCount = 0;
        when(() => mockRepo.getTodayScenario()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) throw Exception('first call fails');
          return _testScenario;
        });

        final c = createContainer();
        c.read(dailyScenarioProvider);
        await Future<void>.delayed(Duration.zero);

        expect(c.read(dailyScenarioProvider), isA<DailyScenarioError>());

        await c.read(dailyScenarioProvider.notifier).retry();

        expect(c.read(dailyScenarioProvider), isA<DailyScenarioLoaded>());
      });

      test('sets loading state before reloading', () async {
        when(() => mockRepo.getTodayScenario()).thenAnswer((_) async {
          throw Exception('fail');
        });

        final c = createContainer();
        c.read(dailyScenarioProvider);
        await Future<void>.delayed(Duration.zero);

        expect(c.read(dailyScenarioProvider), isA<DailyScenarioError>());

        // Start retry but check intermediate state
        final states = <DailyScenarioState>[];
        container.listen(
          dailyScenarioProvider,
          (prev, next) => states.add(next),
        );

        await c.read(dailyScenarioProvider.notifier).retry();

        expect(states.first, isA<DailyScenarioLoading>());
      });
    });
  });
}
