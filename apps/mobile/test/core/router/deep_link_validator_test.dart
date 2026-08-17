import 'package:flutter_test/flutter_test.dart';
import 'package:security_pulse/core/router/deep_link_validator.dart';
import 'package:security_pulse/core/router/route_names.dart';

void main() {
  group('validateDeepLinkPath', () {
    test('maps /today to home', () {
      expect(validateDeepLinkPath('/today'), RoutePaths.home);
    });

    test('maps /progress to history', () {
      expect(validateDeepLinkPath('/progress'), RoutePaths.history);
    });

    test('maps /signin to sign-in', () {
      expect(validateDeepLinkPath('/signin'), RoutePaths.signIn);
    });

    test('is case-insensitive', () {
      expect(validateDeepLinkPath('/TODAY'), RoutePaths.home);
      expect(validateDeepLinkPath('/Progress'), RoutePaths.history);
      expect(validateDeepLinkPath('/SignIn'), RoutePaths.signIn);
    });

    test('returns null for unknown paths', () {
      expect(validateDeepLinkPath('/admin'), isNull);
      expect(validateDeepLinkPath('/settings'), isNull);
      expect(validateDeepLinkPath('/../../etc/passwd'), isNull);
    });

    test('strips query parameters', () {
      expect(validateDeepLinkPath('/today?foo=bar'), RoutePaths.home);
    });

    test('strips fragments', () {
      expect(validateDeepLinkPath('/today#section'), RoutePaths.home);
    });

    test('returns null for empty path', () {
      expect(validateDeepLinkPath(''), isNull);
      expect(validateDeepLinkPath('/'), isNull);
    });
  });
}
