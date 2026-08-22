/// Teacher dashboard screen — School mode (teacher role).
///
/// Shown as the home screen when AppMode.school + SchoolRole.teacher.
/// All data is demo-only. Lets teachers view class stats and navigate
/// to the leaderboard.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';

// ── Demo data ─────────────────────────────────────────────────────────────────

class _RecentActivity {
  const _RecentActivity({required this.studentId, required this.minutesAgo});
  final String studentId;
  final int minutesAgo;
}

const _recentActivity = [
  _RecentActivity(studentId: 'STU-3a9f', minutesAgo: 4),
  _RecentActivity(studentId: 'STU-8c2b', minutesAgo: 12),
  _RecentActivity(studentId: 'STU-1e7d', minutesAgo: 23),
  _RecentActivity(studentId: 'STU-5b4e', minutesAgo: 41),
  _RecentActivity(studentId: 'STU-7f2a', minutesAgo: 68),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teacherDashboardTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.teacherDashboardAssignComingSoon),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.teacherDashboardAssignButton),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Class code chip ──────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.tag_rounded, size: 16),
                label: const Text('SEC-101'),
                backgroundColor: colorScheme.secondaryContainer,
                labelStyle: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Demo banner ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF92400E),
                    semanticLabel: '',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.teacherDashboardDemoBanner,
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── KPI stat cards ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: l10n.teacherDashboardActiveStudents,
                    value: '18/24',
                    icon: Icons.people_rounded,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: l10n.teacherDashboardAvgCompletion,
                    value: '74%',
                    icon: Icons.show_chart_rounded,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: l10n.teacherDashboardTopStreak,
                    value: '14d',
                    icon: Icons.local_fire_department_rounded,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── View leaderboard link ────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => context.pushNamed(RouteNames.leaderboard),
              icon: const Icon(Icons.leaderboard_rounded, size: 18),
              label: Text(l10n.teacherDashboardViewLeaderboard),
            ),
            const SizedBox(height: 24),

            // ── Recent activity ──────────────────────────────────────────
            Text(
              l10n.teacherDashboardRecentActivity,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ..._recentActivity.map(
              (a) => _ActivityRow(
                activity: a,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ),
            // Padding for FAB clearance
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
    required this.textTheme,
  });

  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ── Activity row ──────────────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.activity,
    required this.colorScheme,
    required this.textTheme,
  });

  final _RecentActivity activity;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final timeLabel = activity.minutesAgo < 60
        ? '${activity.minutesAgo} min ago'
        : '${activity.minutesAgo ~/ 60} hr ago';

    return Semantics(
      label: '${activity.studentId} completed a challenge $timeLabel',
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: colorScheme.primary,
              semanticLabel: '',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                activity.studentId,
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              timeLabel,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
