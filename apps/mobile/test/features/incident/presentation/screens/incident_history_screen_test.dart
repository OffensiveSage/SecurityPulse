import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:security_pulse/core/l10n/app_localizations.dart';
import 'package:security_pulse/core/widgets/empty_view.dart';
import 'package:security_pulse/core/widgets/loading_view.dart';
import 'package:security_pulse/features/incident/domain/models/incident_report.dart';
import 'package:security_pulse/features/incident/domain/models/report_type.dart';
import 'package:security_pulse/features/incident/domain/repositories/incident_repository.dart';
import 'package:security_pulse/features/incident/presentation/providers/incident_form_provider.dart';
import 'package:security_pulse/features/incident/presentation/providers/incident_history_provider.dart';
import 'package:security_pulse/features/incident/presentation/screens/incident_history_screen.dart';

class _MockIncidentRepository extends Mock implements IncidentRepository {}

/// A notifier pinned to a fixed state for widget testing.
class _FixedHistoryNotifier extends IncidentHistoryNotifier {
  _FixedHistoryNotifier(this._fixedState);
  final IncidentHistoryState _fixedState;

  @override
  IncidentHistoryState build() => _fixedState;
}

Widget _buildWithFixedState(IncidentHistoryState state) {
  return ProviderScope(
    overrides: [
      incidentHistoryProvider.overrideWith(
        () => _FixedHistoryNotifier(state),
      ),
      incidentRepositoryProvider.overrideWithValue(
        _MockIncidentRepository(),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: IncidentHistoryScreen(),
    ),
  );
}

void main() {
  group('IncidentHistoryScreen', () {
    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        _buildWithFixedState(const IncidentHistoryLoading()),
      );
      await tester.pump();

      expect(find.byType(LoadingView), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(
        _buildWithFixedState(const IncidentHistoryEmpty()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyView), findsOneWidget);
    });

    testWidgets('shows loaded state with report items', (tester) async {
      final reports = [
        IncidentReportSummary(
          id: 'report-1',
          reportType: ReportType.suspiciousEmail,
          title: 'Phishing Attempt',
          severity: IncidentSeverity.medium,
          status: IncidentStatus.submitted,
          createdAt: DateTime(2026, 8, 15),
        ),
        IncidentReportSummary(
          id: 'report-2',
          reportType: ReportType.lostDevice,
          title: 'Lost Company Phone',
          severity: IncidentSeverity.high,
          status: IncidentStatus.investigating,
          createdAt: DateTime(2026, 8, 14),
        ),
      ];

      await tester.pumpWidget(
        _buildWithFixedState(IncidentHistoryLoaded(reports: reports)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phishing Attempt'), findsOneWidget);
      expect(find.text('Lost Company Phone'), findsOneWidget);
      // Type badges
      expect(find.text('Suspicious Email'), findsOneWidget);
      expect(find.text('Lost Device'), findsOneWidget);
    });
  });
}
