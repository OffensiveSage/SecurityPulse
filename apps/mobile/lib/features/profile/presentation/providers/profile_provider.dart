/// Riverpod provider for the profile feature.
///
/// Reuses [scenarioRepositoryProvider] for progress data —
/// no new repository method is required.
library;

import 'dart:math' show min;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../scenario/presentation/providers/daily_scenario_provider.dart';
import 'profile_state.dart';

/// Provides the profile state.
final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    _loadProfile();
    return const ProfileLoading();
  }

  Future<void> _loadProfile() async {
    try {
      final repository = ref.read(scenarioRepositoryProvider);
      final progress = await repository.getProgress();

      // Derive a privacy-safe display name from the auth state.
      // Uses the first 8 characters of the user's UUID — never their real name.
      final authState = ref.read(authProvider);
      final displayName = switch (authState) {
        AuthAuthenticated(:final user) =>
          'Employee #${user.id.substring(0, min(8, user.id.length))}',
        _ => 'Employee',
      };

      if (progress.scenariosAssigned == 0) {
        state = const ProfileEmpty();
      } else {
        state = ProfileLoaded(progress: progress, displayName: displayName);
      }
    } on NetworkFailure {
      state = const ProfileOffline();
    } catch (_) {
      state = const ProfileError(
        failure: ServerFailure(
          message: 'Unable to load profile. Please try again.',
          statusCode: 500,
        ),
      );
    }
  }

  /// Retries loading the profile after an error or offline state.
  Future<void> retry() async {
    state = const ProfileLoading();
    await _loadProfile();
  }
}
