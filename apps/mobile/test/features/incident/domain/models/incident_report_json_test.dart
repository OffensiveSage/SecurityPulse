import 'package:flutter_test/flutter_test.dart';
import 'package:security_pulse/features/incident/domain/models/incident_report.dart';
import 'package:security_pulse/features/incident/domain/models/report_type.dart';

void main() {
  group('ReportType.fromApi', () {
    test('parses known values', () {
      expect(
        ReportType.fromApi('suspicious_email'),
        equals(ReportType.suspiciousEmail),
      );
      expect(
        ReportType.fromApi('lost_device'),
        equals(ReportType.lostDevice),
      );
      expect(
        ReportType.fromApi('unauthorized_access'),
        equals(ReportType.unauthorizedAccess),
      );
    });

    test('defaults to other for unknown values', () {
      expect(ReportType.fromApi('unknown_type'), equals(ReportType.other));
    });
  });

  group('IncidentSeverity.fromApi', () {
    test('parses all severity levels', () {
      expect(
        IncidentSeverity.fromApi('low'),
        equals(IncidentSeverity.low),
      );
      expect(
        IncidentSeverity.fromApi('critical'),
        equals(IncidentSeverity.critical),
      );
    });

    test('defaults to low for unknown values', () {
      expect(
        IncidentSeverity.fromApi('extreme'),
        equals(IncidentSeverity.low),
      );
    });
  });

  group('IncidentStatus.fromApi', () {
    test('parses all status values', () {
      expect(
        IncidentStatus.fromApi('submitted'),
        equals(IncidentStatus.submitted),
      );
      expect(
        IncidentStatus.fromApi('investigating'),
        equals(IncidentStatus.investigating),
      );
    });

    test('defaults to submitted for unknown values', () {
      expect(
        IncidentStatus.fromApi('pending'),
        equals(IncidentStatus.submitted),
      );
    });
  });

  group('IncidentReport.fromJson', () {
    test('parses full JSON correctly', () {
      final json = {
        'id': 'report-123',
        'report_type': 'suspicious_email',
        'title': 'Phishing attempt',
        'description': 'Received a suspicious email from unknown sender.',
        'occurred_at': '2026-08-15T10:30:00Z',
        'severity': 'high',
        'metadata_fields': {'sender_or_url': 'fake@evil.com'},
        'status': 'submitted',
        'created_at': '2026-08-15T11:00:00Z',
        'updated_at': '2026-08-15T11:00:00Z',
      };

      final report = IncidentReport.fromJson(json);

      expect(report.id, equals('report-123'));
      expect(report.reportType, equals(ReportType.suspiciousEmail));
      expect(report.title, equals('Phishing attempt'));
      expect(report.severity, equals(IncidentSeverity.high));
      expect(report.metadataFields, isNotNull);
      expect(report.metadataFields!['sender_or_url'], equals('fake@evil.com'));
      expect(report.status, equals(IncidentStatus.submitted));
    });

    test('parses JSON with null optional fields', () {
      final json = {
        'id': 'report-456',
        'report_type': 'other',
        'title': 'General concern',
        'description': 'Something seemed off in the office today.',
        'occurred_at': '2026-08-15T10:30:00Z',
        'severity': null,
        'metadata_fields': null,
        'status': 'acknowledged',
        'created_at': '2026-08-15T11:00:00Z',
        'updated_at': '2026-08-15T12:00:00Z',
      };

      final report = IncidentReport.fromJson(json);

      expect(report.severity, isNull);
      expect(report.metadataFields, isNull);
      expect(report.status, equals(IncidentStatus.acknowledged));
    });
  });

  group('IncidentReportSummary.fromJson', () {
    test('parses summary JSON correctly', () {
      final json = {
        'id': 'report-789',
        'report_type': 'lost_device',
        'title': 'Lost laptop',
        'severity': 'medium',
        'status': 'investigating',
        'created_at': '2026-08-14T09:00:00Z',
      };

      final summary = IncidentReportSummary.fromJson(json);

      expect(summary.id, equals('report-789'));
      expect(summary.reportType, equals(ReportType.lostDevice));
      expect(summary.title, equals('Lost laptop'));
      expect(summary.severity, equals(IncidentSeverity.medium));
      expect(summary.status, equals(IncidentStatus.investigating));
    });

    test('parses summary with null severity', () {
      final json = {
        'id': 'report-000',
        'report_type': 'other',
        'title': 'Minor concern',
        'severity': null,
        'status': 'submitted',
        'created_at': '2026-08-14T09:00:00Z',
      };

      final summary = IncidentReportSummary.fromJson(json);

      expect(summary.severity, isNull);
    });
  });

  group('DeviceType.fromApi', () {
    test('parses known device types', () {
      expect(DeviceType.fromApi('laptop'), equals(DeviceType.laptop));
      expect(DeviceType.fromApi('usb_drive'), equals(DeviceType.usbDrive));
    });

    test('defaults to other for unknown values', () {
      expect(DeviceType.fromApi('printer'), equals(DeviceType.other));
    });
  });

  group('DataClassification.fromApi', () {
    test('parses known classifications', () {
      expect(
        DataClassification.fromApi('confidential'),
        equals(DataClassification.confidential),
      );
      expect(
        DataClassification.fromApi('restricted'),
        equals(DataClassification.restricted),
      );
    });

    test('defaults to publicData for unknown values', () {
      expect(
        DataClassification.fromApi('top_secret'),
        equals(DataClassification.publicData),
      );
    });
  });
}
