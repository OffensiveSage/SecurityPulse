/// Class leaderboard screen — School mode.
///
/// Shows an anonymised weekly ranking of students in the class.
/// All data is demo-only. The current user's row is highlighted.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';

// ── Demo data ─────────────────────────────────────────────────────────────────

class _LeaderboardEntry {
  const _LeaderboardEntry({
    required this.id,
    required this.streakDays,
    required this.completed,
    required this.isCurrentUser,
  });
  final String id;
  final int streakDays;
  final int completed;
  final bool isCurrentUser;
}

const _entries = [
  _LeaderboardEntry(
    id: 'STU-3a9f',
    streakDays: 14,
    completed: 14,
    isCurrentUser: false,
  ),
  _LeaderboardEntry(
    id: 'STU-8c2b',
    streakDays: 12,
    completed: 13,
    isCurrentUser: false,
  ),
  _LeaderboardEntry(
    id: 'STU-1e7d',
    streakDays: 10,
    completed: 12,
    isCurrentUser: false,
  ),
  _LeaderboardEntry(
    id: 'STU-5b4e',
    streakDays: 9,
    completed: 11,
    isCurrentUser: true,
  ),
  _LeaderboardEntry(
    id: 'STU-7f2a',
    streakDays: 8,
    completed: 10,
    isCurrentUser: false,
  ),
  _LeaderboardEntry(
    id: 'STU-2d6c',
    streakDays: 7,
    completed: 9,
    isCurrentUser: false,
  ),
  _LeaderboardEntry(
    id: 'STU-9a1b',
    streakDays: 5,
    completed: 8,
    isCurrentUser: false,
  ),
  _LeaderboardEntry(
    id: 'STU-4c8d',
    streakDays: 4,
    completed: 6,
    isCurrentUser: false,
  ),
  _LeaderboardEntry(
    id: 'STU-6e3f',
    streakDays: 3,
    completed: 5,
    isCurrentUser: false,
  ),
  _LeaderboardEntry(
    id: 'STU-0b5a',
    streakDays: 1,
    completed: 3,
    isCurrentUser: false,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  String _weekRange() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monday.day} ${months[monday.month]} – ${sunday.day} ${months[sunday.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leaderboardTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Demo banner ──────────────────────────────────────────────────
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
                    l10n.leaderboardDemoBanner,
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Subtitle: week range ─────────────────────────────────────────
          Text(
            '${l10n.leaderboardSubtitle} · ${_weekRange()}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // ── Ranked list ──────────────────────────────────────────────────
          ..._entries.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final data = entry.value;
            return _RankRow(
              rank: rank,
              entry: data,
              colorScheme: colorScheme,
              textTheme: textTheme,
              streakLabel: l10n.leaderboardStreakLabel,
              completedLabel: l10n.leaderboardCompletedLabel,
              youLabel: l10n.leaderboardYouLabel,
            );
          }),
        ],
      ),
    );
  }
}

// ── Rank row ──────────────────────────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.entry,
    required this.colorScheme,
    required this.textTheme,
    required this.streakLabel,
    required this.completedLabel,
    required this.youLabel,
  });

  final int rank;
  final _LeaderboardEntry entry;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String streakLabel;
  final String completedLabel;
  final String youLabel;

  Widget _rankBadge() {
    if (rank <= 3) {
      final color = rank == 1
          ? const Color(0xFFF59E0B) // gold
          : rank == 2
              ? const Color(0xFF9CA3AF) // silver
              : const Color(0xFFB45309); // bronze
      return Semantics(
        label: 'Rank $rank',
        child: Icon(Icons.emoji_events_rounded, color: color, size: 24),
      );
    }
    return Semantics(
      label: 'Rank $rank',
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$rank',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${entry.isCurrentUser ? "$youLabel — " : ""}Rank $rank, ${entry.id}, '
          '${entry.streakDays} $streakLabel, ${entry.completed} $completedLabel',
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: entry.isCurrentUser
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: entry.isCurrentUser
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            _rankBadge(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.id,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (entry.isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            youLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: Colors.orange,
                        semanticLabel: '',
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${entry.streakDays} $streakLabel',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${entry.completed} $completedLabel',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
