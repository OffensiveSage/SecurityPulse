import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:security_pulse/core/theme/app_colors.dart';
import 'package:security_pulse/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    group('light theme', () {
      test('uses Material 3', () {
        expect(AppTheme.light.useMaterial3, isTrue);
      });

      test('primary color matches AppColors.primary', () {
        expect(AppTheme.light.colorScheme.primary, equals(AppColors.primary));
      });

      test('brightness is light', () {
        expect(AppTheme.light.brightness, equals(Brightness.light));
      });
    });

    group('dark theme', () {
      test('uses Material 3', () {
        expect(AppTheme.dark.useMaterial3, isTrue);
      });

      test('brightness is dark', () {
        expect(AppTheme.dark.brightness, equals(Brightness.dark));
      });
    });
  });
}
