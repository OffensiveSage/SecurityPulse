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
import '../../features/scenario/presentation/screens/scenario_shell_screen.dart';
import '../../features/settings/presentation/screens/settings_shell_screen.dart';
import '../error/failures.dart';
import '../widgets/error_view.dart';
import 'route_names.dart';

/// Whether the user is currently authenticated.
///
/// In Phase 1 this is a simple boolean placeholder.
/// Phase 2 replaces this with a Riverpod-based auth state provider.
bool _isAuthenticated = false;

/// Creates the application router.
///
/// [isAuthenticated] is a function that returns the current auth state.
/// This is a parameter so it can be mocked in tests.
GoRouter createAppRouter({
  bool Function() isAuthenticated = _defaultIsAuthenticated,
}) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    redirect: _buildRedirectGuard(isAuthenticated),
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
    routes: [
      // Unauthenticated routes
      GoRoute(
        path: RoutePaths.signIn,
        name: RouteNames.signIn,
        builder: (context, state) => const SignInScreen(),
      ),

      // Protected routes (Phase 2: wrapped in ShellRoute with auth guard)
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const ScenarioShellScreen(),
        routes: [
          GoRoute(
            path: 'scenarios/:scenarioId',
            name: RouteNames.scenario,
            builder: (context, state) => ScenarioShellScreen(
              scenarioId: state.pathParameters['scenarioId'],
            ),
          ),
        ],
      ),

      GoRoute(
        path: RoutePaths.history,
        name: RouteNames.history,
        builder: (context, state) => const ScenarioShellScreen(),
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

bool _defaultIsAuthenticated() => _isAuthenticated;

/// Sets authentication state (Phase 1 placeholder).
///
/// Phase 2 replaces this with Riverpod auth state.
// ignore: avoid_positional_boolean_parameters, avoid_setters_without_getters
set isAuthenticated(bool value) => _isAuthenticated = value;

GoRouterRedirect? _buildRedirectGuard(
  bool Function() isAuthenticated,
) {
  return null; // Phase 2 implements the actual guard
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
