/// Mode selector onboarding screen.
///
/// Shown on first launch before any sign-in prompt. The user picks
/// Personal, School, or Work mode; the choice is persisted in
/// SharedPreferences and determines routing for the rest of the session.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../providers/app_mode_provider.dart';

class ModeSelectorScreen extends ConsumerWidget {
  const ModeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logo / hero ───────────────────────────────────────────────
              Icon(
                Icons.security_rounded,
                size: 56,
                color: colorScheme.primary,
                semanticLabel: '',
              ),
              const SizedBox(height: 16),
              Text(
                l10n.appName,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.modeSelectorTitle,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.modeSelectorSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // ── Mode cards ────────────────────────────────────────────────
              _ModeCard(
                icon: Icons.business_center_rounded,
                title: l10n.modeWorkTitle,
                subtitle: l10n.modeWorkSubtitle,
                colorScheme: colorScheme,
                textTheme: textTheme,
                onTap: () async {
                  await ref
                      .read(appModeProvider.notifier)
                      .setMode(AppMode.work);
                  if (context.mounted) {
                    context.goNamed(RouteNames.signIn);
                  }
                },
              ),
              const SizedBox(height: 12),
              _ModeCard(
                icon: Icons.school_rounded,
                title: l10n.modeSchoolTitle,
                subtitle: l10n.modeSchoolSubtitle,
                colorScheme: colorScheme,
                textTheme: textTheme,
                onTap: () async {
                  await ref
                      .read(appModeProvider.notifier)
                      .setMode(AppMode.school);
                  if (context.mounted) {
                    context.goNamed(RouteNames.classJoin);
                  }
                },
              ),
              const SizedBox(height: 12),
              _ModeCard(
                icon: Icons.person_rounded,
                title: l10n.modePersonalTitle,
                subtitle: l10n.modePersonalSubtitle,
                colorScheme: colorScheme,
                textTheme: textTheme,
                onTap: () async {
                  await ref
                      .read(appModeProvider.notifier)
                      .setMode(AppMode.personal);
                  if (context.mounted) {
                    context.goNamed(RouteNames.guestWelcome);
                  }
                },
              ),

              const SizedBox(height: 32),

              // ── Existing Work account link ─────────────────────────────────
              TextButton(
                onPressed: () {
                  ref.read(appModeProvider.notifier).setMode(AppMode.work);
                  context.goNamed(RouteNames.signIn);
                },
                child: Text(
                  l10n.modeAlreadyHaveAccount,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mode card ─────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title — $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: colorScheme.onPrimaryContainer,
                  semanticLabel: '',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
                semanticLabel: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
