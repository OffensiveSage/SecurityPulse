/// Topic packs screen — Personal mode home tab.
///
/// Shows a grid of security topic categories that users can browse.
/// All counts are demo data. Tapping a topic navigates to the daily
/// scenario screen with a contextual SnackBar.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';

// ── Topic data ────────────────────────────────────────────────────────────────

class _TopicData {
  const _TopicData({
    required this.category,
    required this.icon,
    required this.difficulty,
  });
  final String category;
  final IconData icon;
  final String difficulty;
}

const _topics = [
  _TopicData(
    category: 'Phishing',
    icon: Icons.email_outlined,
    difficulty: 'Beginner',
  ),
  _TopicData(
    category: 'Password Security',
    icon: Icons.password_rounded,
    difficulty: 'Beginner',
  ),
  _TopicData(
    category: 'Social Engineering',
    icon: Icons.people_outline_rounded,
    difficulty: 'Intermediate',
  ),
  _TopicData(
    category: 'Data Protection',
    icon: Icons.lock_outline_rounded,
    difficulty: 'Intermediate',
  ),
  _TopicData(
    category: 'Device Security',
    icon: Icons.phone_android_rounded,
    difficulty: 'Beginner',
  ),
  _TopicData(
    category: 'Physical Security',
    icon: Icons.door_back_door_outlined,
    difficulty: 'Advanced',
  ),
];

const _difficultyColors = {
  'Beginner': Color(0xFF166534), // green-800
  'Intermediate': Color(0xFF92400E), // amber-800
  'Advanced': Color(0xFF991B1B), // red-800
};

const _difficultyBg = {
  'Beginner': Color(0xFFDCFCE7), // green-100
  'Intermediate': Color(0xFFFEF3C7), // amber-100
  'Advanced': Color(0xFFFEE2E2), // red-100
};

// ── Screen ────────────────────────────────────────────────────────────────────

class TopicPacksScreen extends StatelessWidget {
  const TopicPacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.topicPacksTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Demo banner ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB), // amber-50
                border: Border.all(color: const Color(0xFFFDE68A)), // amber-200
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF92400E), // amber-800
                    semanticLabel: '',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.topicPacksDemoBanner,
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Grid ──────────────────────────────────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topics.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, idx) {
                final topic = _topics[idx];
                return _TopicCard(
                  topic: topic,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  challengeCount: l10n.topicPacksChallengeCount,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(l10n.topicPacksStartToast(topic.category)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Topic card ────────────────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.colorScheme,
    required this.textTheme,
    required this.challengeCount,
    required this.onTap,
  });

  final _TopicData topic;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String challengeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColors[topic.difficulty] ?? Colors.grey;
    final diffBg = _difficultyBg[topic.difficulty] ?? Colors.grey.shade100;

    return Semantics(
      button: true,
      label: '${topic.category}, $challengeCount, ${topic.difficulty}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                topic.icon,
                size: 36,
                color: colorScheme.primary,
                semanticLabel: '',
              ),
              const SizedBox(height: 10),
              Text(
                topic.category,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                challengeCount,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: diffBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  topic.difficulty,
                  style: textTheme.labelSmall?.copyWith(
                    color: diffColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
