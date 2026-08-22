/// Radio button selector for incident severity.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/models/report_type.dart';

/// Radio buttons for selecting incident severity (low/medium/high/critical).
class SeveritySelector extends StatelessWidget {
  const SeveritySelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final IncidentSeverity? value;
  final ValueChanged<IncidentSeverity?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.incidentReportSeverityLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        RadioGroup<IncidentSeverity>(
          groupValue: value,
          onChanged: onChanged,
          child: Column(
            children: IncidentSeverity.values.map((severity) {
              return RadioListTile<IncidentSeverity>(
                title: Text(severity.displayName),
                value: severity,
                dense: true,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
