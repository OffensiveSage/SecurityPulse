/// Settings screen with notification preference toggle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../notifications/presentation/providers/notification_preference_provider.dart';

class SettingsShellScreen extends ConsumerWidget {
  const SettingsShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefAsync = ref.watch(notificationPreferenceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsScreenTitle),
      ),
      body: ListView(
        children: [
          prefAsync.when(
            data: (enabled) => SwitchListTile(
              title: Text(l10n.settingsNotificationToggleLabel),
              subtitle: Text(l10n.settingsNotificationToggleDescription),
              value: enabled,
              onChanged: (_) {
                ref.read(notificationPreferenceProvider.notifier).toggle();
              },
              secondary: Semantics(
                label: l10n.settingsNotificationToggleLabel,
                child: const Icon(Icons.notifications_rounded),
              ),
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.notifications_rounded),
              title: Text('...'),
              trailing: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => ListTile(
              leading: const Icon(Icons.notifications_rounded),
              title: Text(l10n.settingsNotificationToggleLabel),
              subtitle: Text(l10n.settingsNotificationPermissionDenied),
            ),
          ),
        ],
      ),
    );
  }
}
