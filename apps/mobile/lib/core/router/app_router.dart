/// Application router configuration using GoRouter.
///
/// Route guards enforce authentication before allowing access to
/// protected routes. Deep links from widgets and notifications are
/// handled through the securitypulse:// URI scheme.
///
/// The four main tabs (Today, History, Reports, Settings) are wrapped in a
/// [StatefulShellRoute] so each tab keeps its own navigation stack.
/// Full-screen flows (sign-in, incident-report) live outside the shell.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/incident/presentation/screens/incident_detail_screen.dart';
import '../../features/incident/presentation/screens/incident_history_screen.dart';
import '../../features/incident/presentation/screens/incident_report_screen.dart';
import '../../features/scenario/presentation/screens/daily_scenario_screen.dart';
import '../../features/scenario/presentation/screens/history_screen.dart';
import '../../features/settings/presentation/screens/settings_shell_screen.dart';
import '../error/failures.dart';
import '../widgets/app_shell.dart';
import '../widgets/error_view.dart';
import 'route_names.dart';

/// Creates the application router.
///
/// [isAuthenticated] returns the current auth state. Used by the
/// redirect guard to enforce authentication on protected routes.
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
      // Deep link redirect routes (from native widgets and notifications).
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

      // Unauthenticated full-screen route.
      GoRoute(
        path: RoutePaths.signIn,
        name: RouteNames.signIn,
        builder: (context, state) => const SignInScreen(),
      ),

      // Full-screen incident report flow — sits outside the shell so it
      // slides over the entire screen without a bottom nav bar.
      GoRoute(
        path: RoutePaths.incidentReport,
        name: RouteNames.incidentReport,
        builder: (context, state) => const IncidentReportScreen(),
      ),

      // Main tab shell — preserves each branch's navigation stack.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: Today (daily scenario).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (context, state) => const DailyScenarioScreen(),
              ),
            ],
          ),

          // Tab 1: History.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.history,
                name: RouteNames.history,
                builder: (context, state) => const HistoryScreen(),
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

          // Tab 3: Settings.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                name: RouteNames.settings,
                builder: (context, state) => const SettingsShellScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

bool _defaultIsNotAuthenticated() => false;

/// Redirect guard that enforces authentication.
///
/// - Unauthenticated users are redirected to sign-in.
/// - Authenticated users trying to access sign-in are redirected to home.
GoRouterRedirect _buildRedirectGuard(bool Function() isAuthenticated) {
  return (BuildContext context, GoRouterState state) {
    final authenticated = isAuthenticated();
    final isSignInRoute = state.matchedLocation == RoutePaths.signIn;

    // Not authenticated and not already on sign-in → redirect to sign-in.
    if (!authenticated && !isSignInRoute) {
      return RoutePaths.signIn;
    }

    // Authenticated but on sign-in → redirect to home.
    if (authenticated && isSignInRoute) {
      return RoutePaths.home;
    }

    // No redirect needed.
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
