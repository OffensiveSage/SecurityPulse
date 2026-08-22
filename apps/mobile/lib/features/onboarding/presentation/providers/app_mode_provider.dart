/// App mode state — persists the user's chosen mode (Personal / School / Work)
/// across sessions using SharedPreferences.
///
/// A null value means mode selection has not yet been completed and the app
/// should route to the mode-selector onboarding screen.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Enums ───────────────────────────────────────────────────────────────────

enum AppMode { personal, school, work }

enum SchoolRole { student, teacher }

// ── Keys ────────────────────────────────────────────────────────────────────

const _kAppMode = 'app_mode';
const _kSchoolRole = 'school_role';
const _kClassCode = 'class_code';
const _kGuestMode = 'guest_mode';

// ── AppMode provider ─────────────────────────────────────────────────────────

class AppModeNotifier extends AsyncNotifier<AppMode?> {
  @override
  Future<AppMode?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAppMode);
    if (raw == null) return null;
    return AppMode.values.where((m) => m.name == raw).firstOrNull;
  }

  Future<void> setMode(AppMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppMode, mode.name);
    state = AsyncData(mode);
  }

  Future<void> setGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppMode, AppMode.personal.name);
    await prefs.setBool(_kGuestMode, true);
    state = const AsyncData(AppMode.personal);
  }

  /// Clears mode on sign-out so onboarding is shown on next launch.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAppMode);
    await prefs.remove(_kGuestMode);
    await prefs.remove(_kSchoolRole);
    await prefs.remove(_kClassCode);
    state = const AsyncData(null);
  }
}

final appModeProvider = AsyncNotifierProvider<AppModeNotifier, AppMode?>(
  AppModeNotifier.new,
);

// ── Guest flag provider ──────────────────────────────────────────────────────

/// True when the user is in Personal mode without a full account.
final isGuestProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kGuestMode) ?? false;
});

// ── School role provider ─────────────────────────────────────────────────────

class SchoolRoleNotifier extends AsyncNotifier<SchoolRole> {
  @override
  Future<SchoolRole> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSchoolRole);
    return raw == 'teacher' ? SchoolRole.teacher : SchoolRole.student;
  }

  Future<void> setRole(SchoolRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSchoolRole, role.name);
    state = AsyncData(role);
  }
}

final schoolRoleProvider =
    AsyncNotifierProvider<SchoolRoleNotifier, SchoolRole>(
  SchoolRoleNotifier.new,
);

// ── Class code provider ───────────────────────────────────────────────────────

class ClassCodeNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kClassCode) ?? '';
  }

  Future<void> setCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kClassCode, code);
    state = AsyncData(code);
  }
}

final classCodeProvider = AsyncNotifierProvider<ClassCodeNotifier, String>(
  ClassCodeNotifier.new,
);
