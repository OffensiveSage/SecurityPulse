/// User progress summary model.
library;

import 'package:flutter/foundation.dart';

/// Summary of a user's scenario completion progress.
@immutable
class UserProgress {
  const UserProgress({
    required this.scenariosAssigned,
    required this.scenariosCompleted,
    required this.currentStreakDays,
    this.campaignEligible,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      scenariosAssigned: json['scenarios_assigned'] as int,
      scenariosCompleted: json['scenarios_completed'] as int,
      currentStreakDays: json['current_streak_days'] as int,
      campaignEligible: json['campaign_eligible'] as bool?,
    );
  }

  final int scenariosAssigned;
  final int scenariosCompleted;
  final int currentStreakDays;

  /// Whether the user is eligible for the current active campaign drawing.
  /// Null when no campaign is active.
  final bool? campaignEligible;
}
