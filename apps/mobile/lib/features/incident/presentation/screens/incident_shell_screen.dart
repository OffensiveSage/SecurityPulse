/// Incident report shell screen — Phase 1 placeholder.
///
/// Phase 5 replaces this with the full incident reporting wizard.
///
/// IMPORTANT: This screen must always display the credential warning.
library;

import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_view.dart';

class IncidentShellScreen extends StatelessWidget {
  const IncidentShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report suspicious activity')),
      body: Column(
        children: [
          // REQUIRED: Credential warning must appear on every incident-related screen.
          // Never remove this warning. See PRODUCT_SPEC.md § 6.3 and SECURITY.md.
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Theme.of(context).colorScheme.error,
                  semanticLabel: 'Warning',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Never enter your password or MFA code in this form.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: EmptyView(
              title: 'Incident reporting',
              message: 'Phase 5 will implement the incident report wizard.',
              icon: Icons.report_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
