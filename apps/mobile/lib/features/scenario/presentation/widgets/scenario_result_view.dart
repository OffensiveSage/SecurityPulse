/// Displays the result after the employee submits an answer.
///
/// Shows whether the answer was correct, an explanation of the scenario,
/// the recommended secure action, and a completion indicator.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/scenario.dart';

class ScenarioResultView extends StatelessWidget {
  const ScenarioResultView({
    required this.scenario,
    required this.result,
    super.key,
  });

  final Scenario scenario;
  final ScenarioResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result banner
          _ResultBanner(
            isCorrect: result.isCorrect,
            title: result.isCorrect
                ? l10n.scenarioCorrectTitle
                : l10n.scenarioIncorrectTitle,
          ),
          const SizedBox(height: 24),

          // Scenario title for context
          Text(
            scenario.title,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),

          // Explanation section
          _InfoSection(
            icon: Icons.lightbulb_outline_rounded,
            heading: l10n.scenarioExplanationHeading,
            body: result.explanation,
          ),
          const SizedBox(height: 16),

          // Recommended action section
          _InfoSection(
            icon: Icons.shield_outlined,
            heading: l10n.scenarioRecommendedActionHeading,
            body: result.recommendedAction,
          ),
          const SizedBox(height: 24),

          // Completion indicator
          Semantics(
            liveRegion: true,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.scenarioCompletedBanner,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.isCorrect,
    required this.title,
  });

  final bool isCorrect;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCorrect ? AppColors.success : AppColors.warning;
    final containerColor =
        isCorrect ? AppColors.successContainer : AppColors.warningContainer;
    final icon =
        isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded;

    return Semantics(
      liveRegion: true,
      label: title,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.heading,
    required this.body,
  });

  final IconData icon;
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  heading,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
