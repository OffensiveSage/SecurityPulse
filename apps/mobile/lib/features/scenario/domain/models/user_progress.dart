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
  });

  /// Creates a [UserProgress] from a JSON map (API response).
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      scenariosAssigned: json['scenarios_assigned'] as int,
      scenariosCompleted: json['scenarios_completed'] as int,
      currentStreakDays: json['current_streak_days'] as int,
    );
  }

  /// Total number of scenarios assigned to the user.
  final int scenariosAssigned;

  /// Number of scenarios the user has completed.
  final int scenariosCompleted;

  /// Current streak of consecutive days with a response.
  final int currentStreakDays;
}
