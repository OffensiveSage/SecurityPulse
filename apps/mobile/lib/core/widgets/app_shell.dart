/// Persistent app shell with bottom navigation.
///
/// Wraps the four main tabs using GoRouter's [StatefulNavigationShell] so
/// each tab preserves its own navigation stack and scroll position.
///
/// Tab labels and icons adapt to the current AppMode:
/// - Work/default: Today, History, Reports, Settings
/// - Personal:     Topics,   History, Reports, Settings
/// - School:       Challenge, Leaderboard, Reports, Settings
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/presentation/providers/app_mode_provider.dart';
import '../l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        final prefs = snap.data;
        final rawMode = prefs?.getString('app_mode');
        final mode = rawMode == null
            ? null
            : AppMode.values.where((m) => m.name == rawMode).firstOrNull;

        final destinations = _buildDestinations(l10n, mode);

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: destinations,
          ),
        );
      },
    );
  }

  List<NavigationDestination> _buildDestinations(
    AppLocalizations l10n,
    AppMode? mode,
  ) {
    final tab0 = switch (mode) {
      AppMode.personal => NavigationDestination(
          icon: const Icon(Icons.topic_outlined),
          selectedIcon: const Icon(Icons.topic_rounded),
          label: l10n.navTopics,
        ),
      AppMode.school => NavigationDestination(
          icon: const Icon(Icons.shield_outlined),
          selectedIcon: const Icon(Icons.shield_rounded),
          label: l10n.navToday,
        ),
      _ => NavigationDestination(
          icon: const Icon(Icons.shield_outlined),
          selectedIcon: const Icon(Icons.shield_rounded),
          label: l10n.navToday,
        ),
    };

    final tab1 = mode == AppMode.school
        ? NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: const Icon(Icons.leaderboard_rounded),
            label: l10n.navLeaderboard,
          )
        : NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history_rounded),
            label: l10n.navHistory,
          );

    return [
      tab0,
      tab1,
      NavigationDestination(
        icon: const Icon(Icons.folder_open_outlined),
        selectedIcon: const Icon(Icons.folder_rounded),
        label: l10n.navReports,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings_rounded),
        label: l10n.navSettings,
      ),
    ];
  }

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Re-tapping the current tab pops to the branch root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
