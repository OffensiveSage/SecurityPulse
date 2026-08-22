/// State classes for the profile feature.
///
/// Uses sealed classes for exhaustive pattern matching in the UI.
library;

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../scenario/domain/models/user_progress.dart';

@immutable
sealed class ProfileState {
  const ProfileState();
}

/// Fetching progress data from the API.
final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Progress data loaded successfully.
final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.progress,
    required this.displayName,
  });

  /// The user's scenario progress summary.
  final UserProgress progress;

  /// Anonymised display name derived from the user's ID (e.g. 'Employee #7f2a9b1c').
  /// Never contains PII.
  final String displayName;
}

/// No progress data available (user has not completed any scenarios).
final class ProfileEmpty extends ProfileState {
  const ProfileEmpty();
}

/// A network error prevented loading profile data.
final class ProfileOffline extends ProfileState {
  const ProfileOffline();
}

/// A non-network error occurred while loading profile data.
final class ProfileError extends ProfileState {
  const ProfileError({required this.failure});
  final Failure failure;
}
