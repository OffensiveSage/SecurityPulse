/// Displays the daily scenario question with answer options.
///
/// Shows the scenario category, prompt text, and selectable answer tiles.
/// The submit button is fixed at the bottom and disabled until an option
/// is selected.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/scenario.dart';
import 'answer_option_tile.dart';

class ScenarioQuestionView extends StatelessWidget {
  const ScenarioQuestionView({
    required this.scenario,
    required this.onOptionSelected,
    required this.onSubmit,
    this.selectedOptionId,
    super.key,
  });

  final Scenario scenario;
  final String? selectedOptionId;
  final ValueChanged<String> onOptionSelected;
  final VoidCallback? onSubmit;

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
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Scrollable content ──────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chip + heading row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconFor(scenario.category),
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.scenarioDailyChallenge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          scenario.category,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Question card with left accent border
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 4,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    scenario.prompt,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                  ),
                ),

                const SizedBox(height: 24),

                // Answer label
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.scenarioSelectPrompt,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Answer tiles — all four always visible
                ...List.generate(
                  scenario.options.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index < scenario.options.length - 1 ? 10.0 : 0.0,
                    ),
                    child: AnswerOptionTile(
                      option: scenario.options[index],
                      index: index,
                      isSelected:
                          scenario.options[index].id == selectedOptionId,
                      onTap: () =>
                          onOptionSelected(scenario.options[index].id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Fixed submit button — sits above bottom nav, no FAB overlap ──
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSubmit,
                  child: Text(l10n.scenarioAnswerSubmit),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
