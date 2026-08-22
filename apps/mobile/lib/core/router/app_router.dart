/// Application router configuration using GoRouter.
///
/// Route guards enforce authentication before allowing access to
/// protected routes. Deep links from widgets and notifications are
/// handled through the securitypulse:// URI scheme.
///
/// The four main tabs (Today, History, Reports, Settings) are wrapped in a
/// [StatefulShellRoute] so each tab keeps its own navigation stack.
/// Full-screen flows (sign-in, incident-report) live outside the shell.
///
/// Multi-mode routing:
/// - Work mode: existing auth-guarded shell unchanged.
/// - Personal mode: guest path bypasses corporate OIDC.
/// - School mode: class-code path bypasses corporate OIDC.
/// All modes show the mode-selector screen on first launch (AppMode == null).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/incident/presentation/screens/incident_detail_screen.dart';
import '../../features/incident/presentation/screens/incident_history_screen.dart';
import '../../features/incident/presentation/screens/incident_report_screen.dart';
import '../../features/onboarding/presentation/providers/app_mode_provider.dart';
import '../../features/onboarding/presentation/screens/class_join_screen.dart';
import '../../features/onboarding/presentation/screens/guest_welcome_screen.dart';
import '../../features/onboarding/presentation/screens/mode_selector_screen.dart';
import '../../features/profile/presentation/screens/profile_shell_screen.dart';
import '../../features/scenario/presentation/screens/daily_scenario_screen.dart';
import '../../features/scenario/presentation/screens/history_screen.dart';
import '../../features/school/presentation/screens/leaderboard_screen.dart';
import '../../features/school/presentation/screens/teacher_dashboard_screen.dart';
import '../../features/settings/presentation/screens/settings_shell_screen.dart';
import '../../features/topics/presentation/screens/topic_packs_screen.dart';
import '../error/failures.dart';
import '../widgets/app_shell.dart';
import '../widgets/error_view.dart';
import 'route_names.dart';

/// Creates the application router.
///
/// [isAuthenticated] returns the current auth state. Used by the
/// redirect guard to enforce authentication on protected Work-mode routes.
///
/// [refreshListenable] triggers route re-evaluation when auth state changes.
GoRouter createAppRouter({
  bool Function() isAuthenticated = _defaultIsNotAuthenticated,
  Listenable? refreshListenable,
}) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    redirect: _buildRedirectGuard(isAuthenticated),
    refreshListenable: refreshListenable,
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
    routes: [
      // ── Onboarding routes (no auth required) ─────────────────────────
      GoRoute(
        path: RoutePaths.modeSelector,
        name: RouteNames.modeSelector,
        builder: (context, state) => const ModeSelectorScreen(),
      ),
      GoRoute(
        path: RoutePaths.guestWelcome,
        name: RouteNames.guestWelcome,
        builder: (context, state) => const GuestWelcomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.classJoin,
        name: RouteNames.classJoin,
        builder: (context, state) => const ClassJoinScreen(),
      ),

      // ── Deep link redirect routes (from native widgets and notifications).
      // These map securitypulse:// paths to internal routes.
      // The auth guard handles unauthenticated access.
      GoRoute(
        path: DeepLinkPaths.today,
        redirect: (_, __) => RoutePaths.home,
      ),
      GoRoute(
        path: DeepLinkPaths.progress,
        redirect: (_, __) => RoutePaths.history,
      ),
      GoRoute(
        path: DeepLinkPaths.signIn,
        redirect: (_, __) => RoutePaths.signIn,
      ),

      // ── Unauthenticated full-screen route ─────────────────────────────
      GoRoute(
        path: RoutePaths.signIn,
        name: RouteNames.signIn,
        builder: (context, state) => const SignInScreen(),
      ),

      // ── Full-screen incident report flow ─────────────────────────────
      GoRoute(
        path: RoutePaths.incidentReport,
        name: RouteNames.incidentReport,
        builder: (context, state) => const IncidentReportScreen(),
      ),

      // ── Standalone routes reachable via push from the shell ──────────
      GoRoute(
        path: RoutePaths.leaderboard,
        name: RouteNames.leaderboard,
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.challenge,
        name: RouteNames.challenge,
        builder: (context, state) => const DailyScenarioScreen(),
      ),

      // ── Main tab shell ────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: Today / Topics / Teacher Dashboard (mode-aware).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (context, state) => const _Tab0Screen(),
              ),
            ],
          ),

          // Tab 1: History / Leaderboard (mode-aware).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.history,
                name: RouteNames.history,
                builder: (context, state) => const _Tab1Screen(),
              ),
            ],
          ),

          // Tab 2: Incident reports.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.myReports,
                name: RouteNames.myReports,
                builder: (context, state) => const IncidentHistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':reportId',
                    name: RouteNames.incidentDetail,
                    builder: (context, state) => IncidentDetailScreen(
                      // pathParameters['reportId'] is always present on this
                      // route — the router will not match without it.
                      reportId: state.pathParameters['reportId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 3: Settings (with profile as a nested sub-route).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                name: RouteNames.settings,
                builder: (context, state) => const SettingsShellScreen(),
                routes: [
                  GoRoute(
                    // Relative path resolves to /settings/profile.
                    path: 'profile',
                    name: RouteNames.profile,
                    builder: (context, state) => const ProfileShellScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

bool _defaultIsNotAuthenticated() => false;

/// Redirect guard supporting multi-mode routing.
///
/// Priority order:
/// 1. If AppMode is not set → mode-selector (highest priority).
/// 2. If Personal/School mode → allow access without corporate auth.
/// 3. If Work mode → enforce existing corporate auth guard.
GoRouterRedirect _buildRedirectGuard(bool Function() isAuthenticated) {
  return (BuildContext context, GoRouterState state) async {
    final location = state.matchedLocation;

    // Onboarding routes are always accessible — never redirect away from them.
    final onboardingPaths = {
      RoutePaths.modeSelector,
      RoutePaths.guestWelcome,
      RoutePaths.classJoin,
    };
    if (onboardingPaths.contains(location)) return null;

    // Read persisted app mode synchronously from cached SharedPreferences.
    // SharedPreferences.getInstance() returns the cached instance after
    // the first await during app startup.
    final prefs = await SharedPreferences.getInstance();
    final rawMode = prefs.getString('app_mode');

    // No mode chosen yet → redirect to mode selector.
    if (rawMode == null) return RoutePaths.modeSelector;

    final mode = AppMode.values.where((m) => m.name == rawMode).firstOrNull;
    if (mode == null) return RoutePaths.modeSelector;

    // Personal / School mode: guests and class-joined users can access the
    // app without corporate OIDC. No further redirect needed.
    if (mode == AppMode.personal || mode == AppMode.school) return null;

    // Work mode: enforce corporate auth guard.
    final authenticated = isAuthenticated();
    final isSignInRoute = location == RoutePaths.signIn;

    if (!authenticated && !isSignInRoute) return RoutePaths.signIn;
    if (authenticated && isSignInRoute) return RoutePaths.home;

    return null;
  };
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ErrorView(
        failure: ServerFailure(
          message: error?.toString() ?? 'Page not found.',
          statusCode: 404,
        ),
      ),
    );
  }
}

// ── Mode-aware tab screens ────────────────────────────────────────────────────
//
// GoRouter StatefulShellRoute branches are defined once at router creation.
// The mode-aware dispatch is handled inside the builder using FutureBuilder
// so each branch can show a different screen based on the persisted AppMode.

class _Tab0Screen extends StatelessWidget {
  const _Tab0Screen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final prefs = snap.data!;
        final rawMode = prefs.getString('app_mode');
        final mode = rawMode == null
            ? null
            : AppMode.values.where((m) => m.name == rawMode).firstOrNull;
        final rawRole = prefs.getString('school_role');
        final isTeacher = rawRole == SchoolRole.teacher.name;

        return switch (mode) {
          AppMode.personal => const TopicPacksScreen(),
          AppMode.school when isTeacher => const TeacherDashboardScreen(),
          _ => const DailyScenarioScreen(),
        };
      },
    );
  }
}

class _Tab1Screen extends StatelessWidget {
  const _Tab1Screen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final prefs = snap.data!;
        final rawMode = prefs.getString('app_mode');
        final mode = rawMode == null
            ? null
            : AppMode.values.where((m) => m.name == rawMode).firstOrNull;

        return mode == AppMode.school
            ? const LeaderboardScreen()
            : const HistoryScreen();
      },
    );
  }
}
