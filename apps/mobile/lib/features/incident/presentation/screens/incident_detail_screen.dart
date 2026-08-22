/// Incident report detail screen.
///
/// Read-only view of a submitted incident report.
/// Includes the credential warning banner per security requirements.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/models/incident_report.dart';
import '../providers/incident_form_provider.dart';
import '../widgets/credential_warning_banner.dart';

class IncidentDetailScreen extends ConsumerStatefulWidget {
  const IncidentDetailScreen({required this.reportId, super.key});

  final String reportId;

  @override
  ConsumerState<IncidentDetailScreen> createState() =>
      _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends ConsumerState<IncidentDetailScreen> {
  IncidentReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      final repo = ref.read(incidentRepositoryProvider);
      final report = await repo.getReportById(widget.reportId);
      if (mounted) {
        setState(() {
          _report = report;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load report details.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.incidentDetailScreenTitle)),
      body: _loading
          ? LoadingView(message: l10n.loadingDefault)
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    const CredentialWarningBanner(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildContent(theme, l10n),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildContent(ThemeData theme, AppLocalizations l10n) {
    final report = _report!; // safe: only called when _report != null

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(report.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Chip(label: Text(report.reportType.displayName)),
        if (report.severity != null) ...[
          const SizedBox(height: 4),
          Chip(label: Text(report.severity!.displayName)),
        ],
        const SizedBox(height: 4),
        Chip(label: Text(report.status.displayName)),
        const SizedBox(height: 16),
        Text(
          l10n.incidentReportDescriptionLabel,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(report.description),
        const SizedBox(height: 16),
        Text(
          l10n.incidentReportOccurredAtLabel,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '${report.occurredAt.year}-'
          '${report.occurredAt.month.toString().padLeft(2, '0')}-'
          '${report.occurredAt.day.toString().padLeft(2, '0')} '
          '${report.occurredAt.hour.toString().padLeft(2, '0')}:'
          '${report.occurredAt.minute.toString().padLeft(2, '0')}',
        ),
        if (report.metadataFields != null &&
            report.metadataFields!.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...report.metadataFields!.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: theme.textTheme.titleSmall,
                  ),
                  Expanded(child: Text('${entry.value}')),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
