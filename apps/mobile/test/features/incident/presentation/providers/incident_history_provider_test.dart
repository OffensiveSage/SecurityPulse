import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:security_pulse/core/error/failures.dart';
import 'package:security_pulse/features/incident/domain/models/incident_report.dart';
import 'package:security_pulse/features/incident/domain/models/report_type.dart';
import 'package:security_pulse/features/incident/domain/repositories/incident_repository.dart';
import 'package:security_pulse/features/incident/presentation/providers/incident_form_provider.dart';
import 'package:security_pulse/features/incident/presentation/providers/incident_history_provider.dart';

class _MockIncidentRepository extends Mock implements IncidentRepository {}

/// Shorthand to stub getMyReports on the mock repository.
When<Future<List<IncidentReportSummary>>> _whenGetMyReports(
  _MockIncidentRepository repo,
) {
  return when(
    () => repo.getMyReports(
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
    ),
  );
}

void main() {
  late _MockIncidentRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = _MockIncidentRepository();
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer() {
    container = ProviderContainer(
      overrides: [
        incidentRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    return container;
  }

  group('IncidentHistoryNotifier', () {
    test('initial state is IncidentHistoryLoading', () {
      _whenGetMyReports(mockRepo).thenAnswer((_) async => []);

      final c = createContainer();
      expect(c.read(incidentHistoryProvider), isA<IncidentHistoryLoading>());
    });

    test('transitions to IncidentHistoryLoaded with reports', () async {
      final reports = [
        IncidentReportSummary(
          id: 'report-1',
          reportType: ReportType.suspiciousEmail,
          title: 'Phishing attempt',
          severity: IncidentSeverity.medium,
          status: IncidentStatus.submitted,
          createdAt: DateTime(2026, 8, 15),
        ),
      ];

      _whenGetMyReports(mockRepo).thenAnswer((_) async => reports);

      final c = createContainer();
      c.read(incidentHistoryProvider);
      await Future<void>.delayed(Duration.zero);

      final state = c.read(incidentHistoryProvider);
      expect(state, isA<IncidentHistoryLoaded>());
      expect(
        (state as IncidentHistoryLoaded).reports,
        hasLength(1),
      );
      expect(state.reports.first.title, equals('Phishing attempt'));
    });

    test('transitions to IncidentHistoryEmpty when no reports', () async {
      _whenGetMyReports(mockRepo).thenAnswer((_) async => []);

      final c = createContainer();
      c.read(incidentHistoryProvider);
      await Future<void>.delayed(Duration.zero);

      expect(
        c.read(incidentHistoryProvider),
        isA<IncidentHistoryEmpty>(),
      );
    });

    test('transitions to IncidentHistoryError on failure', () async {
      _whenGetMyReports(mockRepo).thenAnswer((_) async {
        throw Exception('network error');
      });

      final c = createContainer();
      c.read(incidentHistoryProvider);
      await Future<void>.delayed(Duration.zero);

      final state = c.read(incidentHistoryProvider);
      expect(state, isA<IncidentHistoryError>());
      expect(
        (state as IncidentHistoryError).failure,
        isA<ServerFailure>(),
      );
    });

    test('transitions to IncidentHistoryError on NetworkFailure', () async {
      _whenGetMyReports(mockRepo).thenAnswer((_) async {
        throw const NetworkFailure();
      });

      final c = createContainer();
      c.read(incidentHistoryProvider);
      await Future<void>.delayed(Duration.zero);

      final state = c.read(incidentHistoryProvider);
      expect(state, isA<IncidentHistoryError>());
      expect(
        (state as IncidentHistoryError).failure,
        isA<NetworkFailure>(),
      );
    });

    test('retry reloads reports', () async {
      var callCount = 0;
      _whenGetMyReports(mockRepo).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('first fail');
        return [
          IncidentReportSummary(
            id: 'report-1',
            reportType: ReportType.lostDevice,
            title: 'Loaded After Retry',
            status: IncidentStatus.submitted,
            createdAt: DateTime(2026, 8, 15),
          ),
        ];
      });

      final c = createContainer();
      c.read(incidentHistoryProvider);
      await Future<void>.delayed(Duration.zero);

      expect(
        c.read(incidentHistoryProvider),
        isA<IncidentHistoryError>(),
      );

      await c.read(incidentHistoryProvider.notifier).retry();

      final state = c.read(incidentHistoryProvider);
      expect(state, isA<IncidentHistoryLoaded>());
      expect(
        (state as IncidentHistoryLoaded).reports.first.title,
        equals('Loaded After Retry'),
      );
    });
  });
}
