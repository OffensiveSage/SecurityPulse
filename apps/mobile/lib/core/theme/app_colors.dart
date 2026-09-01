/// Design token: color palette for Security Pulse.
///
/// "Midnight Pulse" premium palette — electric indigo × deep violet.
/// Do not hardcode color values anywhere else in the codebase.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand Gradients ──────────────────────────────────────────────────────
  /// Primary brand gradient: indigo → violet.
  static const List<Color> brandGradient = [
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
  ];

  /// Deep hero gradient: near-black indigo → rich violet.
  static const List<Color> heroGradient = [
    Color(0xFF1E1B4B),
    Color(0xFF3730A3),
    Color(0xFF4C1D95),
  ];

  /// Cyan-to-indigo gradient used for education/accent contexts.
  static const List<Color> cyanGradient = [
    Color(0xFF0891B2),
    Color(0xFF4F46E5),
  ];

  /// Violet-to-rose gradient used for personal/creative contexts.
  static const List<Color> roseGradient = [
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
  ];

  // ── Primary (Electric Indigo) ─────────────────────────────────────────────
  static const Color primary = Color(0xFF4F46E5); // indigo-600
  static const Color primaryDark = Color(0xFF3730A3); // indigo-800
  static const Color primaryDeep = Color(0xFF1E1B4B); // indigo-950
  static const Color primaryLight = Color(0xFF818CF8); // indigo-400
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Secondary (Deep Violet) ───────────────────────────────────────────────
  static const Color secondary = Color(0xFF7C3AED); // violet-600
  static const Color secondaryLight = Color(0xFFA78BFA); // violet-400
  static const Color secondaryDark = Color(0xFF5B21B6); // violet-800
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ── Accent (Electric Cyan) ───────────────────────────────────────────────
  static const Color accent = Color(0xFF0891B2); // cyan-600
  static const Color accentLight = Color(0xFF22D3EE); // cyan-400

  // ── Error ────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);

  // ── Warning ──────────────────────────────────────────────────────────────
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);

  // ── Success ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFF34D399);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccess = Color(0xFFFFFFFF);

  // ── Light Mode Surfaces ───────────────────────────────────────────────────
  static const Color background = Color(0xFFFAFBFF); // barely-lavender white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant =
      Color(0xFFEEECFF); // indigo-tinted card bg
  static const Color onSurface = Color(0xFF0D0C1E); // near-black indigo
  static const Color onSurfaceVariant = Color(0xFF5B5880); // muted indigo-gray
  static const Color outline = Color(0xFFCDCBF0); // soft indigo border
  static const Color outlineVariant =
      Color(0xFFE8E7FF); // barely-visible border

  // ── Dark Mode Surfaces ────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF06041A); // deep midnight
  static const Color darkSurface = Color(0xFF100E2C); // dark indigo surface
  static const Color darkSurfaceVariant =
      Color(0xFF1A1645); // elevated dark surface
  static const Color darkOnSurface = Color(0xFFEDE9FE); // lavender white
  static const Color darkOnSurfaceVariant = Color(0xFFA5B4FC); // indigo-300
  static const Color darkOutline = Color(0xFF2D2A65); // dark indigo border
}
