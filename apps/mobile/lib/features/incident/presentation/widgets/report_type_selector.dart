/// Dropdown selector for incident report types.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/models/report_type.dart';

/// A dropdown that lets the user select an incident report type.
class ReportTypeSelector extends StatelessWidget {
  const ReportTypeSelector({
    required this.value,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final ReportType? value;
  final ValueChanged<ReportType?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DropdownButtonFormField<ReportType>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: l10n.incidentReportTypeLabel,
        hintText: l10n.incidentReportTypeHint,
        errorText: errorText,
        border: const OutlineInputBorder(),
      ),
      items: ReportType.values.map((type) {
        return DropdownMenuItem<ReportType>(
          value: type,
          child: Semantics(
            label: '${type.displayName}: ${type.description}',
            child: Text(type.displayName),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
