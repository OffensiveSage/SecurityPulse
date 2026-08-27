/// Challenge intro card shown before the user starts the daily scenario.
///
/// Displays the category, scenario title, streak, and a "Start Challenge"
/// button so the question feels like something worth opening, not homework.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/scenario.dart';
import '../../domain/models/user_progress.dart';
import '../providers/progress_provider.dart';

class ScenarioChallengeCard extends ConsumerWidget {
  const ScenarioChallengeCard({
    required this.scenario,
    required this.onStart,
    super.key,
  });

  final Scenario scenario;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progressAsync = ref.watch(progressProvider);

    final streak = progressAsync.maybeWhen(
      data: (p) => p.currentStreakDays,
      orElse: () => 0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Streak / progress row ────────────────────────────────────
          _StreakBanner(streak: streak, progress: progressAsync),

          const SizedBox(height: 28),

          // ── Section label ────────────────────────────────────────────
          Text(
            l10n.scenarioChallengeReadyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // ── Challenge card ───────────────────────────────────────────
          _ChallengeCard(scenario: scenario, l10n: l10n),

          const SizedBox(height: 32),

          // ── Start button ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                l10n.scenarioStartButton,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.streak, required this.progress});

  final int streak;
  final AsyncValue<UserProgress> progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Streak
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Text(
                    '$streak',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                AppLocalizations.of(context).profileStreakLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(width: 24),
          Container(width: 1, height: 40, color: AppColors.outline),
          const SizedBox(width: 24),

          // Completion
          progress.maybeWhen(
            data: (p) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.scenariosCompleted}/${p.scenariosAssigned}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  AppLocalizations.of(context).leaderboardCompletedLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.scenario, required this.l10n});

  final Scenario scenario;
  final AppLocalizations l10n;

  static IconData _iconFor(String category) {
    return switch (category.toLowerCase()) {
      'phishing' => Icons.email_outlined,
      'mfa fatigue' => Icons.phonelink_lock_rounded,
      'ransomware' => Icons.lock_outlined,
      'social engineering' => Icons.people_outline_rounded,
      'password security' => Icons.password_rounded,
      _ => Icons.security_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coloured header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconFor(scenario.category),
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scenario.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Meta row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.scenarioEstimatedTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.quiz_outlined,
                  size: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.scenarioOptionsCount(scenario.options.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+ XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
