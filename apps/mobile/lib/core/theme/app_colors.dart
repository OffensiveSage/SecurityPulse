/// Design token: color palette for Security Pulse.
///
/// These are the source-of-truth colors. Do not hardcode color values
/// anywhere else in the codebase. Reference these constants instead.
///
/// Branding colors are placeholders pending governance confirmation.
/// See ARCHITECTURE.md § Governance decisions.
library;

import 'package:flutter/material.dart';

/// Primary brand colors (placeholder — awaiting brand confirmation)
abstract final class AppColors {
  // Primary
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryLight = Color(0xFF3F74E7);
  static const Color primaryDark = Color(0xFF0F3DA6);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary
  static const Color secondary = Color(0xFF0E9F6E);
  static const Color secondaryLight = Color(0xFF31C48D);
  static const Color secondaryDark = Color(0xFF057A55);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Error / Danger
  static const Color error = Color(0xFFE02424);
  static const Color errorLight = Color(0xFFF05252);
  static const Color errorContainer = Color(0xFFFDE8E8);
  static const Color onError = Color(0xFFFFFFFF);

  // Warning
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);

  // Success
  static const Color success = Color(0xFF057A55);
  static const Color successContainer = Color(0xFFDEF7EC);

  // Neutrals
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color onSurface = Color(0xFF111928);
  static const Color onSurfaceVariant = Color(0xFF6B7280);
  static const Color outline = Color(0xFFD1D5DB);
  static const Color outlineVariant = Color(0xFFE5E7EB);

  // Background
  static const Color background = Color(0xFFF9FAFB);
  static const Color onBackground = Color(0xFF111928);

  // Dark mode overrides
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkSurfaceVariant = Color(0xFF374151);
  static const Color darkOnSurface = Color(0xFFF9FAFB);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);
  static const Color darkBackground = Color(0xFF111928);
  static const Color darkOutline = Color(0xFF4B5563);
}
