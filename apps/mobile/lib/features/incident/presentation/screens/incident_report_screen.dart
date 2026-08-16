/// Incident report form screen.
///
/// Full-screen form for submitting a security incident report.
/// Handles all states: editing, submitting, success, error.
///
/// REQUIRED: Credential warning banner must always be visible.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../providers/incident_form_provider.dart';
import '../providers/incident_form_state.dart';
import '../widgets/conditional_fields.dart';
import '../widgets/credential_warning_banner.dart';
import '../widgets/report_type_selector.dart';
import '../widgets/severity_selector.dart';
import '../widgets/urgent_guidance_banner.dart';

class IncidentReportScreen extends ConsumerWidget {
  const IncidentReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incidentFormProvider);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(incidentFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.incidentReportScreenTitle)),
      body: switch (state) {
        IncidentFormEditing() => _IncidentForm(
            state: state,
            notifier: notifier,
            l10n: l10n,
          ),
        IncidentFormSubmitting() => LoadingView(
            message: l10n.incidentReportSubmitting,
          ),
        IncidentFormSuccess(
          :final reportId,
          :final title,
          :final reportType,
          :final submittedAt,
        ) =>
          _ReceiptView(
            reportId: reportId,
            title: title,
            reportTypeName: reportType.displayName,
            submittedAt: submittedAt,
            l10n: l10n,
          ),
        IncidentFormError(:final failure) => ErrorView(
            failure: failure,
            onRetry: notifier.retryFromError,
          ),
      },
    );
  }
}

class _IncidentForm extends StatelessWidget {
  const _IncidentForm({
    required this.state,
    required this.notifier,
    required this.l10n,
  });

  final IncidentFormEditing state;
  final IncidentFormNotifier notifier;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final errors = state.validationErrors;

    return Column(
      children: [
        const CredentialWarningBanner(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReportTypeSelector(
                  value: state.reportType,
                  onChanged: (type) {
                    if (type != null) notifier.updateReportType(type);
                  },
                  errorText: errors['reportType'],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  initialValue: state.title,
                  decoration: InputDecoration(
                    labelText: l10n.incidentReportTitleLabel,
                    hintText: l10n.incidentReportTitleHint,
                    errorText: errors['title'],
                    border: const OutlineInputBorder(),
                  ),
                  maxLength: 100,
                  onChanged: notifier.updateTitle,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  initialValue: state.description,
                  decoration: InputDecoration(
                    labelText: l10n.incidentReportDescriptionLabel,
                    hintText: l10n.incidentReportDescriptionHint,
                    errorText: errors['description'],
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  maxLength: 2000,
                  onChanged: notifier.updateDescription,
                ),
                const SizedBox(height: 16),

                _DateTimePicker(
                  value: state.occurredAt,
                  onChanged: notifier.updateOccurredAt,
                  errorText: errors['occurredAt'],
                  l10n: l10n,
                ),
                const SizedBox(height: 16),

                SeveritySelector(
                  value: state.severity,
                  onChanged: notifier.updateSeverity,
                ),

                if (state.showUrgentGuidance) const UrgentGuidanceBanner(),
                const SizedBox(height: 16),

                ConditionalFields(
                  reportType: state.reportType,
                  metadataFields: state.metadataFields,
                  onFieldChanged: notifier.updateMetadataField,
                ),
                const SizedBox(height: 16),

                // Attachment placeholder (disabled).
                Tooltip(
                  message: l10n.incidentReportAttachmentComingSoon,
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.attach_file_rounded),
                    label: Text(l10n.incidentReportAttachmentLabel),
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: notifier.submit,
                  child: Text(l10n.incidentReportSubmitButton),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({
    required this.value,
    required this.onChanged,
    required this.l10n,
    this.errorText,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final displayText = value != null
        ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-'
            '${value!.day.toString().padLeft(2, '0')} '
            '${value!.hour.toString().padLeft(2, '0')}:'
            '${value!.minute.toString().padLeft(2, '0')}'
        : '';

    return InkWell(
      onTap: () => _pickDateTime(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.incidentReportOccurredAtLabel,
          errorText: errorText,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(
          displayText,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value ?? now),
    );
    if (time == null) return;

    onChanged(
      DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }
}

class _ReceiptView extends StatelessWidget {
  const _ReceiptView({
    required this.reportId,
    required this.title,
    required this.reportTypeName,
    required this.submittedAt,
    required this.l10n,
  });

  final String reportId;
  final String title;
  final String reportTypeName;
  final DateTime submittedAt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortId = reportId.length > 8 ? reportId.substring(0, 8) : reportId;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: theme.colorScheme.primary,
            semanticLabel: l10n.incidentReceiptTitle,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.incidentReceiptTitle,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.incidentReceiptReportId(shortId),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(reportTypeName, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '${submittedAt.year}-'
            '${submittedAt.month.toString().padLeft(2, '0')}-'
            '${submittedAt.day.toString().padLeft(2, '0')} '
            '${submittedAt.hour.toString().padLeft(2, '0')}:'
            '${submittedAt.minute.toString().padLeft(2, '0')}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.go('/'),
            child: Text(l10n.incidentReceiptDoneButton),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/my-reports'),
            child: Text(l10n.incidentReceiptViewReportsButton),
          ),
        ],
      ),
    );
  }
}
