/// Daily scenario screen — the employee home screen.
///
/// Displays the daily cybersecurity scenario and handles the full
/// question → selection → submission → result lifecycle.
///
/// All screen states are handled:
/// - Loading: while fetching the scenario
/// - Empty: no scenario assigned today
/// - Error: recoverable server error
/// - Offline: no network connectivity
/// - Loaded: scenario ready for answering
/// - Submitting: answer being sent
/// - Completed: result displayed
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/offline_view.dart';
import '../providers/daily_scenario_provider.dart';
import '../providers/daily_scenario_state.dart';
import '../widgets/scenario_question_view.dart';
import '../widgets/scenario_result_view.dart';

class DailyScenarioScreen extends ConsumerWidget {
  const DailyScenarioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyScenarioProvider);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(dailyScenarioProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.incidentReport),
        icon: const Icon(
          Icons.shield_rounded,
          semanticLabel: '',
        ),
        label: Text(l10n.incidentReportFabLabel),
        tooltip: l10n.incidentReportFabLabel,
      ),
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
        DailyScenarioOffline() => OfflineView(
            onRetry: notifier.retry,
          ),
        DailyScenarioLoaded(:final scenario, :final selectedOptionId) =>
          ScenarioQuestionView(
            scenario: scenario,
            selectedOptionId: selectedOptionId,
            onOptionSelected: notifier.selectOption,
            onSubmit: selectedOptionId != null ? notifier.submitAnswer : null,
          ),
        DailyScenarioSubmitting() => LoadingView(
            message: l10n.scenarioSubmitting,
          ),
        DailyScenarioCompleted(:final scenario, :final result) =>
          ScenarioResultView(
            scenario: scenario,
            result: result,
          ),
      },
    );
  }
}
