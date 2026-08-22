/// Settings screen.
///
/// Sections:
///   Account  — Profile navigation, Sign out
///   Preferences — Daily notification toggle
///   App     — Version, Privacy Policy, Support
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
          // ── Account section ────────────────────────────────────────────
          _SectionHeader(title: l10n.settingsAccountSectionTitle),
          ListTile(
            leading: Semantics(
              label: l10n.settingsProfileLabel,
              child: const Icon(Icons.person_outline_rounded),
            ),
            title: Text(l10n.settingsProfileLabel),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => context.pushNamed(RouteNames.profile),
          ),
          ListTile(
            leading: Semantics(
              label: l10n.settingsSignOutLabel,
              child: Icon(
                Icons.logout_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            title: Text(
              l10n.settingsSignOutLabel,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmSignOut(context, ref, l10n),
          ),
          const Divider(height: 1),

          // ── Preferences section ────────────────────────────────────────
          _SectionHeader(title: l10n.settingsPreferencesSectionTitle),
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
          const Divider(height: 1),

          // ── App section ────────────────────────────────────────────────
          _SectionHeader(title: l10n.settingsAppSectionTitle),
          ListTile(
            leading: Semantics(
              label: l10n.settingsVersionLabel,
              child: const Icon(Icons.info_outline_rounded),
            ),
            title: Text(l10n.settingsVersionLabel),
            // Version is hardcoded until package_info_plus is added.
            subtitle: const Text('1.0.0 (build 1)'),
          ),
          ListTile(
            leading: Semantics(
              label: l10n.settingsPrivacyLabel,
              child: const Icon(Icons.privacy_tip_outlined),
            ),
            title: Text(l10n.settingsPrivacyLabel),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () => _showUrlDialog(
              context,
              l10n,
              l10n.settingsPrivacyLabel,
              'https://example.com/privacy',
            ),
          ),
          ListTile(
            leading: Semantics(
              label: l10n.settingsSupportLabel,
              child: const Icon(Icons.support_agent_rounded),
            ),
            title: Text(l10n.settingsSupportLabel),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () => _showUrlDialog(
              context,
              l10n,
              l10n.settingsSupportLabel,
              'mailto:security@example.com',
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog before signing out.
  ///
  /// After confirmation, calls [AuthNotifier.signOut]. The GoRouter's
  /// refreshListenable detects the state change and redirects to sign-in.
  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.signOutCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.buttonSignOut),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(authProvider.notifier).signOut();
      // GoRouter redirect guard fires automatically — no manual navigation needed.
    }
  }

  /// Shows an unlaunchable URL in a dialog with selectable text.
  ///
  /// A url_launcher dependency is not currently in pubspec.yaml.
  /// Users can long-press the URL to copy it.
  void _showUrlDialog(
    BuildContext context,
    AppLocalizations l10n,
    String title,
    String url,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settingsUrlDialogBody),
            const SizedBox(height: 8),
            SelectableText(
              url,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.settingsUrlDialogClose),
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}
