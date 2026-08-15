/// Displays the daily scenario question with answer options.
///
/// Shows the scenario category, prompt text, and selectable answer tiles.
/// The submit button is fixed at the bottom and disabled until an option
/// is selected.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    scenario.category,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Section title
                Text(
                  l10n.scenarioDailyChallenge,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // Scenario prompt
                Text(
                  scenario.prompt,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // Answer selection label
                Text(
                  l10n.scenarioSelectPrompt,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                // Answer options
                ...List.generate(
                  scenario.options.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index < scenario.options.length - 1 ? 8.0 : 0.0,
                    ),
                    child: AnswerOptionTile(
                      option: scenario.options[index],
                      index: index,
                      isSelected:
                          scenario.options[index].id == selectedOptionId,
                      onTap: () => onOptionSelected(
                        scenario.options[index].id,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Fixed submit button at bottom
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmit,
                child: Text(l10n.scenarioAnswerSubmit),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
