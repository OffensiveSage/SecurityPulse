/// Deep link path validation and mapping.
///
/// Only a whitelist of paths is accepted from the securitypulse:// scheme.
/// Unknown paths are rejected to prevent malicious navigation.
/// See THREAT_MODEL.md T-05.
library;

import 'route_names.dart';

/// Maps a deep link path to an internal route path.
///
/// Returns the mapped route path, or `null` if the path is not recognized.
/// Query parameters and fragments are ignored.
///
/// Accepted paths:
/// - `/today` → home screen (daily scenario)
/// - `/progress` → history screen
/// - `/signin` → sign-in screen
String? validateDeepLinkPath(String path) {
  // Strip query parameters and fragments.
  final cleanPath = Uri.parse(path).path.toLowerCase();

  return switch (cleanPath) {
    '/today' => RoutePaths.home,
    '/progress' => RoutePaths.history,
    '/signin' => RoutePaths.signIn,
    _ => null,
  };
}
