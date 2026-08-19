/// Incident report history screen.
///
/// Displays the user's submitted incident reports.
/// All screen states are handled: loading, empty, error, loaded.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/models/incident_report.dart';
import '../../domain/models/report_type.dart';
import '../providers/incident_history_provider.dart';

class IncidentHistoryScreen extends ConsumerWidget {
  const IncidentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incidentHistoryProvider);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(incidentHistoryProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.incidentHistoryScreenTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.incidentReport),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.incidentReportFabLabel),
        tooltip: l10n.incidentReportFabLabel,
      ),
      body: switch (state) {
        IncidentHistoryLoading() => LoadingView(
            message: l10n.loadingDefault,
          ),
        IncidentHistoryEmpty() => EmptyView(
            title: l10n.incidentHistoryEmptyTitle,
            message: l10n.incidentHistoryEmptyMessage,
            icon: Icons.report_rounded,
          ),
        IncidentHistoryError(:final failure) => ErrorView(
            failure: failure,
            onRetry: notifier.retry,
          ),
        IncidentHistoryLoaded(:final reports) => _ReportList(reports: reports),
      },
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({required this.reports});

  final List<IncidentReportSummary> reports;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _ReportItem(report: reports[index]);
      },
    );
  }
}

class _ReportItem extends StatelessWidget {
  const _ReportItem({required this.report});

  final IncidentReportSummary report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(
        report.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          _TypeBadge(typeName: report.reportType.displayName),
          const SizedBox(width: 8),
          if (report.severity != null) ...[
            _SeverityIndicator(severity: report.severity!),
            const SizedBox(width: 8),
          ],
          Text(
            report.status.displayName,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      trailing: Text(
        _formatDate(report.createdAt),
        style: theme.textTheme.bodySmall,
      ),
      onTap: () => context.push('/my-reports/${report.id}'),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.typeName});

  final String typeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        typeName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _SeverityIndicator extends StatelessWidget {
  const _SeverityIndicator({required this.severity});

  final IncidentSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Text(
      severity.displayName,
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
