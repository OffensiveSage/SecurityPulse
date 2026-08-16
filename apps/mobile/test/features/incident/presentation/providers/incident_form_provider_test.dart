import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:security_pulse/core/error/failures.dart';
import 'package:security_pulse/features/incident/domain/models/report_type.dart';
import 'package:security_pulse/features/incident/domain/repositories/incident_repository.dart';
import 'package:security_pulse/features/incident/presentation/providers/incident_form_provider.dart';
import 'package:security_pulse/features/incident/presentation/providers/incident_form_state.dart';

class _MockIncidentRepository extends Mock implements IncidentRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(ReportType.other);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(IncidentSeverity.low);
  });

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

  group('IncidentFormNotifier', () {
    test('initial state is IncidentFormEditing', () {
      final c = createContainer();
      final state = c.read(incidentFormProvider);
      expect(state, isA<IncidentFormEditing>());
      final editing = state as IncidentFormEditing;
      expect(editing.title, isEmpty);
      expect(editing.description, isEmpty);
      expect(editing.reportType, isNull);
      expect(editing.occurredAt, isNotNull);
    });

    test('updateReportType sets report type and clears metadata', () {
      final c = createContainer();
      final notifier = c.read(incidentFormProvider.notifier);

      notifier.updateReportType(ReportType.suspiciousEmail);

      final state = c.read(incidentFormProvider) as IncidentFormEditing;
      expect(state.reportType, equals(ReportType.suspiciousEmail));
      expect(state.metadataFields, isEmpty);
    });

    test('updateTitle sets title', () {
      final c = createContainer();
      final notifier = c.read(incidentFormProvider.notifier);

      notifier.updateTitle('Test title');

      final state = c.read(incidentFormProvider) as IncidentFormEditing;
      expect(state.title, equals('Test title'));
    });

    test('updateSeverity sets severity', () {
      final c = createContainer();
      final notifier = c.read(incidentFormProvider.notifier);

      notifier.updateSeverity(IncidentSeverity.critical);

      final state = c.read(incidentFormProvider) as IncidentFormEditing;
      expect(state.severity, equals(IncidentSeverity.critical));
    });

    test('validate returns false when required fields are missing', () {
      final c = createContainer();
      final notifier = c.read(incidentFormProvider.notifier);

      final result = notifier.validate();

      expect(result, isFalse);
      final state = c.read(incidentFormProvider) as IncidentFormEditing;
      expect(state.validationErrors, isNotEmpty);
      expect(state.validationErrors, contains('reportType'));
      expect(state.validationErrors, contains('title'));
      expect(state.validationErrors, contains('description'));
    });

    test('validate returns false for short title', () {
      final c = createContainer();
      final notifier = c.read(incidentFormProvider.notifier);

      notifier.updateReportType(ReportType.suspiciousEmail);
      notifier.updateTitle('Ab');
      notifier.updateDescription(
        'This is a long enough description for the validation.',
      );

      final result = notifier.validate();

      expect(result, isFalse);
      final state = c.read(incidentFormProvider) as IncidentFormEditing;
      expect(state.validationErrors, contains('title'));
    });

    test('validate returns true with all required fields', () {
      final c = createContainer();
      final notifier = c.read(incidentFormProvider.notifier);

      notifier.updateReportType(ReportType.suspiciousEmail);
      notifier.updateTitle('Valid incident title');
      notifier.updateDescription(
        'This is a valid description that is long enough.',
      );

      final result = notifier.validate();

      expect(result, isTrue);
    });

    test('submit transitions to success on valid data', () async {
      when(
        () => mockRepo.submitReport(
          reportType: any(named: 'reportType'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          occurredAt: any(named: 'occurredAt'),
          severity: any(named: 'severity'),
          metadataFields: any(named: 'metadataFields'),
        ),
      ).thenAnswer((_) async => 'report-id-123');

      final c = createContainer();
      final notifier = c.read(incidentFormProvider.notifier);

      notifier.updateReportType(ReportType.suspiciousEmail);
      notifier.updateTitle('Valid incident title');
      notifier.updateDescription(
        'This is a valid description that is long enough.',
      );

      await notifier.submit();

      final state = c.read(incidentFormProvider);
      expect(state, isA<IncidentFormSuccess>());
      final success = state as IncidentFormSuccess;
      expect(success.reportId, equals('report-id-123'));
      expect(success.title, equals('Valid incident title'));
      expect(success.reportType, equals(ReportType.suspiciousEmail));
    });

    test('submit transitions to error on failure', () async {
      when(
        () => mockRepo.submitReport(
          reportType: any(named: 'reportType'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          occurredAt: any(named: 'occurredAt'),
          severity: any(named: 'severity'),
          metadataFields: any(named: 'metadataFields'),
        ),
      ).thenThrow(
        const RateLimitFailure(),
      );

      final c = createContainer();
      final notifier = c.read(incidentFormProvider.notifier);

      notifier.updateReportType(ReportType.lostDevice);
      notifier.updateTitle('Lost my laptop');
      notifier.updateDescription(
        'I lost my company laptop at the airport yesterday.',
      );

      await notifier.submit();

      final state = c.read(incidentFormProvider);
      expect(state, isA<IncidentFormError>());
      final error = state as IncidentFormError;
      expect(error.failure, isA<RateLimitFailure>());
    });

    test('retryFromError restores previous editing state', () async {
      when(
        () => mockRepo.submitReport(
          reportType: any(named: 'reportType'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          occurredAt: any(named: 'occurredAt'),
          severity: any(named: 'severity'),
          metadataFields: any(named: 'metadataFields'),
        ),
      ).thenThrow(
        const ServerFailure(message: 'Server error', statusCode: 500),
      );

      final c = createContainer();
      final notifier = c.read(incidentFormProvider.notifier);

      notifier.updateReportType(ReportType.suspiciousEmail);
      notifier.updateTitle('My incident title');
      notifier.updateDescription(
        'This is a valid description for the incident.',
      );

      await notifier.submit();
      expect(c.read(incidentFormProvider), isA<IncidentFormError>());

      notifier.retryFromError();

      final state = c.read(incidentFormProvider);
      expect(state, isA<IncidentFormEditing>());
      final editing = state as IncidentFormEditing;
      expect(editing.title, equals('My incident title'));
      expect(editing.reportType, equals(ReportType.suspiciousEmail));
    });
  });

  group('IncidentFormEditing.showUrgentGuidance', () {
    test('returns true for critical severity', () {
      const editing = IncidentFormEditing(
        severity: IncidentSeverity.critical,
      );
      expect(editing.showUrgentGuidance, isTrue);
    });

    test('returns true for unauthorized access', () {
      const editing = IncidentFormEditing(
        reportType: ReportType.unauthorizedAccess,
      );
      expect(editing.showUrgentGuidance, isTrue);
    });

    test('returns true for data exposure', () {
      const editing = IncidentFormEditing(
        reportType: ReportType.dataExposure,
      );
      expect(editing.showUrgentGuidance, isTrue);
    });

    test('returns false for low severity email', () {
      const editing = IncidentFormEditing(
        reportType: ReportType.suspiciousEmail,
        severity: IncidentSeverity.low,
      );
      expect(editing.showUrgentGuidance, isFalse);
    });
  });
}
