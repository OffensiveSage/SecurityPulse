/// Credential warning banner for incident report screens.
///
/// REQUIRED: This banner must appear on every incident-related screen.
/// See PRODUCT_SPEC.md § 6.3 and SECURITY.md.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Displays a prominent warning not to enter passwords or MFA codes.
class CredentialWarningBanner extends StatelessWidget {
  const CredentialWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: l10n.incidentReportWarningCredentials,
      child: Container(
        width: double.infinity,
        color: theme.colorScheme.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: theme.colorScheme.error,
              semanticLabel: '',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.incidentReportWarningCredentials,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
