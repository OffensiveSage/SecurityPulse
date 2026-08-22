/// Riverpod provider for user progress summary.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/user_progress.dart';
import 'daily_scenario_provider.dart';

/// Fetches the user's progress summary from the repository.
final progressProvider = FutureProvider<UserProgress>((ref) async {
  final repository = ref.read(scenarioRepositoryProvider);
  return repository.getProgress();
});
