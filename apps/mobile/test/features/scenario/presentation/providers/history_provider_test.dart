import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:security_pulse/core/error/failures.dart';
import 'package:security_pulse/features/scenario/domain/models/response_record.dart';
import 'package:security_pulse/features/scenario/domain/repositories/scenario_repository.dart';
import 'package:security_pulse/features/scenario/presentation/providers/daily_scenario_provider.dart';
import 'package:security_pulse/features/scenario/presentation/providers/history_provider.dart';

class _MockScenarioRepository extends Mock implements ScenarioRepository {}

/// Shorthand to stub getHistory on the mock repository.
When<Future<List<ResponseRecord>>> _whenGetHistory(
  _MockScenarioRepository repo,
) {
  return when(
    () => repo.getHistory(
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
    ),
  );
}

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

  group('HistoryNotifier', () {
    test('initial state is HistoryLoading', () {
      _whenGetHistory(mockRepo).thenAnswer((_) async => []);

      final c = createContainer();
      expect(c.read(historyProvider), isA<HistoryLoading>());
    });

    test('transitions to HistoryLoaded with records', () async {
      final records = [
        ResponseRecord(
          id: 'resp-1',
          scenarioId: 'scenario-1',
          scenarioTitle: 'Test Scenario',
          submittedAt: DateTime(2026, 8, 13),
          isCorrect: true,
        ),
      ];

      _whenGetHistory(mockRepo).thenAnswer((_) async => records);

      final c = createContainer();
      c.read(historyProvider);
      await Future<void>.delayed(Duration.zero);

      final state = c.read(historyProvider);
      expect(state, isA<HistoryLoaded>());
      expect((state as HistoryLoaded).records, hasLength(1));
      expect(state.records.first.scenarioTitle, equals('Test Scenario'));
    });

    test('transitions to HistoryEmpty when no records', () async {
      _whenGetHistory(mockRepo).thenAnswer((_) async => []);

      final c = createContainer();
      c.read(historyProvider);
      await Future<void>.delayed(Duration.zero);

      expect(c.read(historyProvider), isA<HistoryEmpty>());
    });

    test('transitions to HistoryError on failure', () async {
      _whenGetHistory(mockRepo).thenAnswer((_) async {
        throw Exception('network error');
      });

      final c = createContainer();
      c.read(historyProvider);
      await Future<void>.delayed(Duration.zero);

      final state = c.read(historyProvider);
      expect(state, isA<HistoryError>());
      expect((state as HistoryError).failure, isA<ServerFailure>());
    });

    test('transitions to HistoryError on NetworkFailure', () async {
      _whenGetHistory(mockRepo).thenAnswer((_) async {
        throw const NetworkFailure();
      });

      final c = createContainer();
      c.read(historyProvider);
      await Future<void>.delayed(Duration.zero);

      final state = c.read(historyProvider);
      expect(state, isA<HistoryError>());
      expect((state as HistoryError).failure, isA<NetworkFailure>());
    });

    test('retry reloads history', () async {
      var callCount = 0;
      _whenGetHistory(mockRepo).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('first fail');
        return [
          ResponseRecord(
            id: 'resp-1',
            scenarioId: 'scenario-1',
            scenarioTitle: 'Loaded After Retry',
            submittedAt: DateTime(2026, 8, 13),
            isCorrect: false,
          ),
        ];
      });

      final c = createContainer();
      c.read(historyProvider);
      await Future<void>.delayed(Duration.zero);

      expect(c.read(historyProvider), isA<HistoryError>());

      await c.read(historyProvider.notifier).retry();

      final state = c.read(historyProvider);
      expect(state, isA<HistoryLoaded>());
      expect(
        (state as HistoryLoaded).records.first.scenarioTitle,
        equals('Loaded After Retry'),
      );
    });
  });
}
