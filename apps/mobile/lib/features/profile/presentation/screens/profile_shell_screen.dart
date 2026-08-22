/// Profile screen — shows anonymised progress stats and earned badges.
///
/// All displayed data is aggregated and anonymised.
/// The display name is derived from the user's UUID, never their real name.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/offline_view.dart';
import '../../../scenario/domain/models/user_progress.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_state.dart';

class ProfileShellScreen extends ConsumerWidget {
  const ProfileShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileScreenTitle),
      ),
      body: switch (state) {
        ProfileLoading() => LoadingView(message: l10n.loadingDefault),
        ProfileEmpty() => EmptyView(
            title: l10n.profileEmptyTitle,
            message: l10n.profileEmptyMessage,
            icon: Icons.person_rounded,
          ),
        ProfileOffline() => OfflineView(onRetry: notifier.retry),
        ProfileError(:final failure) => ErrorView(
            failure: failure,
            onRetry: notifier.retry,
          ),
        ProfileLoaded(:final progress, :final displayName) => _ProfileBody(
            progress: progress,
            displayName: displayName,
            l10n: l10n,
          ),
      },
    );
  }
}

// ── Profile body ───────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.progress,
    required this.displayName,
    required this.l10n,
  });

  final UserProgress progress;
  final String displayName;
  final AppLocalizations l10n;

  String get _accuracyDisplay {
    if (progress.scenariosAssigned == 0) return '—';
    final pct = (progress.scenariosCompleted / progress.scenariosAssigned * 100)
        .round();
    return '$pct%';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile header card ──────────────────────────────────────────
          _ProfileHeaderCard(
            displayName: displayName,
            streakDays: progress.currentStreakDays,
            l10n: l10n,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 16),

          // ── Stats row ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: l10n.profileTotalResponsesLabel,
                  value: '${progress.scenariosCompleted}',
                  icon: Icons.check_circle_outline_rounded,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  label: l10n.profileAccuracySemantics(_accuracyDisplay),
                  excludeSemantics: true,
                  child: _StatCard(
                    label: l10n.profileAccuracyLabel,
                    value: _accuracyDisplay,
                    icon: Icons.show_chart_rounded,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: l10n.profileStreakDaysLabel,
                  value: '${progress.currentStreakDays}d',
                  icon: Icons.local_fire_department_rounded,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Badges section ───────────────────────────────────────────────
          Text(
            l10n.profileBadgesSectionTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _BadgesGrid(progress: progress, l10n: l10n, colorScheme: colorScheme),
        ],
      ),
    );
  }
}

// ── Profile header card ────────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.displayName,
    required this.streakDays,
    required this.l10n,
    required this.colorScheme,
  });

  final String displayName;
  final int streakDays;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar placeholder
          CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.person_rounded,
              size: 28,
              color: colorScheme.onPrimaryContainer,
              semanticLabel: '',
            ),
          ),
          const SizedBox(height: 12),
          // Masked display name
          Semantics(
            label: l10n.profileDisplayNameSemantics(displayName),
            child: Text(
              displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Streak row
          if (streakDays > 0)
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: Colors.orange,
                  semanticLabel: '',
                ),
                const SizedBox(width: 4),
                Semantics(
                  label: '$streakDays ${l10n.profileStreakLabel}',
                  child: Text(
                    '$streakDays ${l10n.profileStreakLabel}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary, semanticLabel: ''),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Badges grid ────────────────────────────────────────────────────────────────

class _BadgesGrid extends StatelessWidget {
  const _BadgesGrid({
    required this.progress,
    required this.l10n,
    required this.colorScheme,
  });

  final UserProgress progress;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final badges = <_BadgeData>[
      if (progress.scenariosCompleted >= 1)
        _BadgeData(
          icon: Icons.star_rounded,
          label: l10n.profileBadgeFirstScenario,
          color: Colors.amber,
        ),
      if (progress.currentStreakDays >= 7)
        _BadgeData(
          icon: Icons.local_fire_department_rounded,
          label: l10n.profileBadgeWeekStreak,
          color: Colors.orange,
        ),
      if (progress.campaignEligible ?? false)
        _BadgeData(
          icon: Icons.emoji_events_rounded,
          label: l10n.profileBadgeCampaignEligible,
          color: colorScheme.primary,
        ),
    ];

    if (badges.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Complete more scenarios to earn badges.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: badges
          .map((b) => _BadgeTile(data: b, colorScheme: colorScheme))
          .toList(),
    );
  }
}

class _BadgeData {
  const _BadgeData({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.data, required this.colorScheme});
  final _BadgeData data;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: data.label,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data.icon, size: 32, color: data.color, semanticLabel: ''),
            const SizedBox(height: 6),
            Text(
              data.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
