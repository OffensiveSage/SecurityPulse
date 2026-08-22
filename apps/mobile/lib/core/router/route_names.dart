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
  static const String myReports = '/my-reports';
  static const String incidentDetail = '/my-reports/:reportId';
  static const String profile = '/profile';
  static const String settings = '/settings';
  // Onboarding
  static const String modeSelector = '/onboarding/mode';
  static const String guestWelcome = '/onboarding/guest';
  static const String classJoin = '/onboarding/join-class';
  // Personal mode
  static const String topicPacks = '/topics';
  static const String challenge = '/challenge';
  // School mode
  static const String leaderboard = '/leaderboard';
  static const String teacherDashboard = '/teacher';
}

abstract final class RouteNames {
  static const String signIn = 'sign-in';
  static const String home = 'home';
  static const String scenario = 'scenario';
  static const String scenarioResult = 'scenario-result';
  static const String history = 'history';
  static const String incidentReport = 'incident-report';
  static const String incidentReceipt = 'incident-receipt';
  static const String myReports = 'my-reports';
  static const String incidentDetail = 'incident-detail';
  static const String profile = 'profile';
  static const String settings = 'settings';
  // Onboarding
  static const String modeSelector = 'mode-selector';
  static const String guestWelcome = 'guest-welcome';
  static const String classJoin = 'class-join';
  // Personal mode
  static const String topicPacks = 'topic-packs';
  static const String challenge = 'challenge';
  // School mode
  static const String leaderboard = 'leaderboard';
  static const String teacherDashboard = 'teacher-dashboard';
}

/// Deep link scheme for widget and notification links.
///
/// Format: securitypulse://<path>
/// Example: securitypulse:///scenarios/550e8400-e29b-41d4-a716-446655440000
abstract final class DeepLinkScheme {
  static const String scheme = 'securitypulse';
  static const String host = '';
}

/// Accepted deep link paths from native widgets and notifications.
///
/// Only these paths are recognized. Unknown paths are rejected
/// to prevent malicious navigation. See THREAT_MODEL.md T-05.
abstract final class DeepLinkPaths {
  static const String today = '/today';
  static const String progress = '/progress';
  static const String signIn = '/signin';
}
