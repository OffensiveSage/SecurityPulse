/// Daily scenario screen — the employee home screen.
///
/// Lifecycle:
///   Loading → Loaded (intro card) → [user taps Start] → question view
///             → Submitting → Completed (result)
///
/// All screen states are handled:
/// - Loading: while fetching the scenario
/// - Empty: no scenario assigned today
/// - Error: recoverable server error
/// - Offline: no network connectivity
/// - Loaded: shows challenge intro card first, then question on tap
/// - Submitting: answer being sent
/// - Completed: result displayed
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/offline_view.dart';
import '../providers/daily_scenario_provider.dart';
import '../providers/daily_scenario_state.dart';
import '../widgets/scenario_challenge_card.dart';
import '../widgets/scenario_question_view.dart';
import '../widgets/scenario_result_view.dart';

class DailyScenarioScreen extends ConsumerStatefulWidget {
  const DailyScenarioScreen({super.key});

  @override
  ConsumerState<DailyScenarioScreen> createState() =>
      _DailyScenarioScreenState();
}

class _DailyScenarioScreenState extends ConsumerState<DailyScenarioScreen> {
  /// Whether the user has tapped "Start Challenge" to reveal the question.
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyScenarioProvider);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(dailyScenarioProvider.notifier);

    // Reset the intro card whenever a fresh scenario loads.
    ref.listen<DailyScenarioState>(dailyScenarioProvider, (previous, next) {
      if (next is DailyScenarioLoaded && previous is! DailyScenarioLoaded) {
        setState(() => _started = false);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: switch (state) {
        DailyScenarioLoading() => LoadingView(
            message: l10n.scenarioLoadingMessage,
          ),
        DailyScenarioEmpty() => EmptyView(
            title: l10n.emptyScenarioTitle,
            message: l10n.emptyScenarioMessage,
            icon: Icons.quiz_rounded,
          ),
        DailyScenarioError(:final failure) => ErrorView(
            failure: failure,
            onRetry: notifier.retry,
          ),
        DailyScenarioOffline() => OfflineView(onRetry: notifier.retry),
        DailyScenarioLoaded(:final scenario, :final selectedOptionId) =>
          _started
              ? ScenarioQuestionView(
                  scenario: scenario,
                  selectedOptionId: selectedOptionId,
                  onOptionSelected: notifier.selectOption,
                  onSubmit:
                      selectedOptionId != null ? notifier.submitAnswer : null,
                )
              : ScenarioChallengeCard(
                  scenario: scenario,
                  onStart: () => setState(() => _started = true),
                ),
        DailyScenarioSubmitting() => LoadingView(
            message: l10n.scenarioSubmitting,
          ),
        DailyScenarioCompleted(:final scenario, :final result) =>
          ScenarioResultView(scenario: scenario, result: result),
      },
    );
  }
}
