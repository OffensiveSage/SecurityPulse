import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:security_pulse/core/l10n/app_localizations.dart';
import 'package:security_pulse/core/widgets/loading_view.dart';
import 'package:security_pulse/features/incident/domain/models/report_type.dart';
import 'package:security_pulse/features/incident/presentation/providers/incident_form_provider.dart';
import 'package:security_pulse/features/incident/presentation/providers/incident_form_state.dart';
import 'package:security_pulse/features/incident/presentation/screens/incident_report_screen.dart';
import 'package:security_pulse/features/incident/presentation/widgets/credential_warning_banner.dart';
import 'package:security_pulse/features/incident/presentation/widgets/urgent_guidance_banner.dart';

/// A notifier that returns a fixed state without loading from a repository.
class _FixedFormNotifier extends IncidentFormNotifier {
  _FixedFormNotifier(this._fixedState);
  final IncidentFormState _fixedState;

  @override
  IncidentFormState build() => _fixedState;
}

/// Builds a test app pinned to a fixed incident form state.
Widget _buildWithFixedState(IncidentFormState state) {
  return ProviderScope(
    overrides: [
      incidentFormProvider.overrideWith(() => _FixedFormNotifier(state)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: IncidentReportScreen(),
    ),
  );
}

void main() {
  group('IncidentReportScreen', () {
    group('editing state', () {
      testWidgets('shows credential warning banner', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            IncidentFormEditing(occurredAt: DateTime.now()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CredentialWarningBanner), findsOneWidget);
      });

      testWidgets('shows form fields', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            IncidentFormEditing(occurredAt: DateTime.now()),
          ),
        );
        await tester.pumpAndSettle();

        // Should have title, description fields, and submit button
        expect(find.byType(TextFormField), findsAtLeast(2));
        expect(find.byType(FilledButton), findsOneWidget);
      });

      testWidgets(
        'shows urgent guidance banner for critical severity',
        (tester) async {
          await tester.pumpWidget(
            _buildWithFixedState(
              IncidentFormEditing(
                occurredAt: DateTime.now(),
                severity: IncidentSeverity.critical,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(UrgentGuidanceBanner), findsOneWidget);
        },
      );

      testWidgets(
        'shows urgent guidance banner for unauthorized access',
        (tester) async {
          await tester.pumpWidget(
            _buildWithFixedState(
              IncidentFormEditing(
                occurredAt: DateTime.now(),
                reportType: ReportType.unauthorizedAccess,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(UrgentGuidanceBanner), findsOneWidget);
        },
      );

      testWidgets(
        'does not show urgent guidance for low severity email',
        (tester) async {
          await tester.pumpWidget(
            _buildWithFixedState(
              IncidentFormEditing(
                occurredAt: DateTime.now(),
                reportType: ReportType.suspiciousEmail,
                severity: IncidentSeverity.low,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(UrgentGuidanceBanner), findsNothing);
        },
      );
    });

    group('submitting state', () {
      testWidgets('shows loading view', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(const IncidentFormSubmitting()),
        );
        await tester.pump();

        expect(find.byType(LoadingView), findsOneWidget);
      });
    });

    group('success state', () {
      testWidgets('shows receipt with report ID and title', (tester) async {
        await tester.pumpWidget(
          _buildWithFixedState(
            IncidentFormSuccess(
              reportId: 'abcdef12-3456-7890-abcd-ef1234567890',
              title: 'My Incident Report',
              reportType: ReportType.suspiciousEmail,
              submittedAt: DateTime(2026, 8, 15, 10, 30),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Shows truncated report ID (first 8 chars)
        expect(find.textContaining('abcdef12'), findsOneWidget);
        // Shows title
        expect(find.text('My Incident Report'), findsOneWidget);
        // Shows report type
        expect(find.text('Suspicious Email'), findsOneWidget);
        // Shows done button
        expect(find.byType(FilledButton), findsOneWidget);
      });
    });
  });
}
