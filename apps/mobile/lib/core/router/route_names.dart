/// Named route constants for GoRouter.
///
/// Use these constants everywhere a route path or name is referenced.
/// Never hardcode route path strings in widget code.
library;

abstract final class RoutePaths {
  static const String signIn = '/sign-in';
  static const String home = '/';
  static const String scenario = '/scenarios/:scenarioId';
  static const String scenarioResult = '/scenarios/:scenarioId/result';
  static const String history = '/history';
  static const String incidentReport = '/incident-report';
  static const String incidentReceipt = '/incident-report/:reportId/receipt';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

abstract final class RouteNames {
  static const String signIn = 'sign-in';
  static const String home = 'home';
  static const String scenario = 'scenario';
  static const String scenarioResult = 'scenario-result';
  static const String history = 'history';
  static const String incidentReport = 'incident-report';
  static const String incidentReceipt = 'incident-receipt';
  static const String profile = 'profile';
  static const String settings = 'settings';
}

/// Deep link scheme for widget and notification links.
///
/// Format: securitypulse://<path>
/// Example: securitypulse:///scenarios/550e8400-e29b-41d4-a716-446655440000
abstract final class DeepLinkScheme {
  static const String scheme = 'securitypulse';
  static const String host = '';
}
