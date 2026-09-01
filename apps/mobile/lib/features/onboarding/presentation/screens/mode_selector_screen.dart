/// Mode selector onboarding screen — premium "Midnight Pulse" design.
///
/// Shown on first launch. User picks Personal, School, or Work mode.
/// Each mode card has a unique gradient identity.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
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
              // ── Hero ─────────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.brandGradient,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 40,
                    color: Colors.white,
                    semanticLabel: '',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.appName,
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.modeSelectorTitle,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.modeSelectorSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // ── Work card — indigo × violet ───────────────────────────────
              _ModeCard(
                icon: Icons.business_center_rounded,
                title: l10n.modeWorkTitle,
                subtitle: l10n.modeWorkSubtitle,
                gradient: AppColors.brandGradient,
                badge: 'Enterprise',
                colorScheme: colorScheme,
                textTheme: textTheme,
                onTap: () async {
                  await ref
                      .read(appModeProvider.notifier)
                      .setMode(AppMode.work);
                  if (context.mounted) context.goNamed(RouteNames.signIn);
                },
              ),
              const SizedBox(height: 14),

              // ── School card — cyan × indigo ───────────────────────────────
              _ModeCard(
                icon: Icons.school_rounded,
                title: l10n.modeSchoolTitle,
                subtitle: l10n.modeSchoolSubtitle,
                gradient: AppColors.cyanGradient,
                colorScheme: colorScheme,
                textTheme: textTheme,
                onTap: () async {
                  await ref
                      .read(appModeProvider.notifier)
                      .setMode(AppMode.school);
                  if (context.mounted) context.goNamed(RouteNames.classJoin);
                },
              ),
              const SizedBox(height: 14),

              // ── Personal card — violet × rose ─────────────────────────────
              _ModeCard(
                icon: Icons.person_rounded,
                title: l10n.modePersonalTitle,
                subtitle: l10n.modePersonalSubtitle,
                gradient: AppColors.roseGradient,
                colorScheme: colorScheme,
                textTheme: textTheme,
                onTap: () async {
                  await ref
                      .read(appModeProvider.notifier)
                      .setMode(AppMode.personal);
                  if (context.mounted) context.goNamed(RouteNames.guestWelcome);
                },
              ),

              const SizedBox(height: 32),

              TextButton(
                onPressed: () {
                  ref.read(appModeProvider.notifier).setMode(AppMode.work);
                  context.goNamed(RouteNames.signIn);
                },
                child: Text(l10n.modeAlreadyHaveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mode Card ──────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final String? badge;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: '$title — $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isDark ? AppColors.darkOutline : AppColors.outlineVariant,
                width: 1.5,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Gradient icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: Colors.white,
                    semanticLabel: '',
                  ),
                ),
                const SizedBox(width: 16),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradient,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: gradient.first.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: gradient.first,
                    semanticLabel: '',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
