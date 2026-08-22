/// History screen — displays the employee's response history.
///
/// All screen states are handled:
/// - Loading: while fetching history
/// - Empty: no responses yet
/// - Error: recoverable server/network error
/// - Loaded: list of past responses
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/models/response_record.dart';
import '../../domain/models/user_progress.dart';
import '../providers/history_provider.dart';
import '../providers/progress_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyProvider);
    final progressAsync = ref.watch(progressProvider);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(historyProvider.notifier);

    // Progress card is shown when data is available; errors are silently skipped.
    final progressCard = progressAsync.maybeWhen(
      data: (progress) => _ProgressSummaryCard(progress: progress),
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyScreenTitle)),
      body: switch (state) {
        HistoryLoading() => Column(
            children: [
              if (progressCard != null) progressCard,
              Expanded(child: LoadingView(message: l10n.loadingDefault)),
            ],
          ),
        HistoryEmpty() => Column(
            children: [
              if (progressCard != null) progressCard,
              Expanded(
                child: EmptyView(
                  title: l10n.emptyHistoryTitle,
                  message: l10n.emptyHistoryMessage,
                  icon: Icons.history_rounded,
                ),
              ),
            ],
          ),
        HistoryError(:final failure) => Column(
            children: [
              if (progressCard != null) progressCard,
              Expanded(
                child: ErrorView(
                  failure: failure,
                  onRetry: notifier.retry,
                ),
              ),
            ],
          ),
        HistoryLoaded(:final records) => Column(
            children: [
              if (progressCard != null) progressCard,
              Expanded(child: _HistoryList(records: records)),
            ],
          ),
      },
    );
  }
}

/// Card displayed above the history list summarising the user's progress.
class _ProgressSummaryCard extends StatelessWidget {
  const _ProgressSummaryCard({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isEligible = progress.campaignEligible ?? false;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Streak
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.progressStreakDays(progress.currentStreakDays),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.progressCompleted(
                      progress.scenariosCompleted,
                      progress.scenariosAssigned,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Campaign eligibility badge — only shown when eligible.
            if (isEligible)
              Semantics(
                label: l10n.campaignEligibleSemantics,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade400),
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      l10n.campaignEligibleBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.records});

  final List<ResponseRecord> records;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: records.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = records[index];
        return _HistoryItem(record: record, l10n: l10n);
      },
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.record,
    required this.l10n,
  });

  final ResponseRecord record;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = record.isCorrect;

    return ListTile(
      leading: Icon(
        isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: isCorrect ? theme.colorScheme.primary : theme.colorScheme.error,
        semanticLabel:
            isCorrect ? l10n.historyItemCorrect : l10n.historyItemIncorrect,
      ),
      title: Text(
        record.scenarioTitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatDate(record.submittedAt),
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
