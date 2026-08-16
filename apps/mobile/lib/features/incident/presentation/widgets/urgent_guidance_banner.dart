/// Urgent guidance banner for critical incidents.
///
/// Displayed when severity is critical or report type is
/// unauthorized_access or data_exposure.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Placeholder SOC phone number for development.
const _socPhoneNumber = '+1-555-SOC-LINE';

/// Shows guidance to contact the Security Operations Center.
class UrgentGuidanceBanner extends StatelessWidget {
  const UrgentGuidanceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: l10n.incidentReportUrgentGuidance(_socPhoneNumber),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.tertiary,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.phone_in_talk_rounded,
              color: theme.colorScheme.tertiary,
              semanticLabel: '',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.incidentReportUrgentGuidance(_socPhoneNumber),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
