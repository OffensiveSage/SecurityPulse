/// Application router configuration using GoRouter.
///
/// Route guards enforce authentication before allowing access to
/// protected routes. Deep links from widgets and notifications are
/// handled through the securitypulse:// URI scheme.
///
/// All route paths are defined in RoutePaths to avoid magic strings.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/incident/presentation/screens/incident_shell_screen.dart';
import '../../features/profile/presentation/screens/profile_shell_screen.dart';
import '../../features/scenario/presentation/screens/daily_scenario_screen.dart';
import '../../features/scenario/presentation/screens/history_screen.dart';
import '../../features/settings/presentation/screens/settings_shell_screen.dart';
import '../error/failures.dart';
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
      // Unauthenticated routes
      GoRoute(
        path: RoutePaths.signIn,
        name: RouteNames.signIn,
        builder: (context, state) => const SignInScreen(),
      ),

      // Protected routes
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const DailyScenarioScreen(),
        routes: [
          GoRoute(
            path: 'scenarios/:scenarioId',
            name: RouteNames.scenario,
            builder: (context, state) => const DailyScenarioScreen(),
          ),
        ],
      ),

      GoRoute(
        path: RoutePaths.history,
        name: RouteNames.history,
        builder: (context, state) => const HistoryScreen(),
      ),

      GoRoute(
        path: RoutePaths.incidentReport,
        name: RouteNames.incidentReport,
        builder: (context, state) => const IncidentShellScreen(),
      ),

      GoRoute(
        path: RoutePaths.profile,
        name: RouteNames.profile,
        builder: (context, state) => const ProfileShellScreen(),
      ),

      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsShellScreen(),
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
