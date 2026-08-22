/// Displays the result after the employee submits an answer.
///
/// Full-screen celebratory layout:
/// - Hero section (gradient) with large icon and result title
/// - Scrollable explanation and recommended action cards
/// - Streak/motivational banner at the bottom
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/scenario.dart';
import '../providers/progress_provider.dart';

class ScenarioResultView extends ConsumerWidget {
  const ScenarioResultView({
    required this.scenario,
    required this.result,
    super.key,
  });

  final Scenario scenario;
  final ScenarioResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final progressAsync = ref.watch(progressProvider);

    final isCorrect = result.isCorrect;
    final heroColors = isCorrect
        ? [AppColors.secondary, AppColors.secondaryDark]
        : [const Color(0xFFD97706), const Color(0xFFB45309)];

    final streak = progressAsync.maybeWhen(
      data: (p) => p.currentStreakDays,
      orElse: () => 0,
    );

    return Column(
      children: [
        // ── Hero result section ──────────────────────────────────────────
        Container(
          width: double.infinity,
          height: size.height * 0.28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: heroColors,
            ),
          ),
          child: Semantics(
            liveRegion: true,
            label: isCorrect
                ? l10n.scenarioCorrectTitle
                : l10n.scenarioIncorrectTitle,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 12),
                Text(
                  isCorrect
                      ? l10n.scenarioCorrectTitle
                      : l10n.scenarioIncorrectTitle,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Scrollable explanation ───────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scenario title for context
                Text(
                  scenario.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                _InfoCard(
                  icon: Icons.lightbulb_rounded,
                  iconColor: const Color(0xFFD97706),
                  heading: l10n.scenarioExplanationHeading,
                  body: result.explanation,
                ),
                const SizedBox(height: 12),

                _InfoCard(
                  icon: Icons.shield_rounded,
                  iconColor: AppColors.primary,
                  heading: l10n.scenarioRecommendedActionHeading,
                  body: result.recommendedAction,
                ),
                const SizedBox(height: 20),

                // ── Streak / motivation banner ───────────────────────────
                if (isCorrect)
                  _StreakBanner(streak: streak, l10n: l10n)
                else
                  _MotivationBanner(l10n: l10n),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.heading,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                heading,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.streak, required this.l10n});

  final int streak;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryDark],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.scenarioStreakKept,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (streak > 0)
                Text(
                  '$streak day streak',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MotivationBanner extends StatelessWidget {
  const _MotivationBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('💪', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.scenarioKeepGoing,
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
