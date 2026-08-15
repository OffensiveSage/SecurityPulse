/// Application root widget.
///
/// Sets up:
/// - GoRouter for navigation and deep links
/// - MaterialApp with light and dark themes
/// - Localization delegates
/// - Authentication state listening for route guards
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/auth_state.dart';

class SecurityPulseApp extends ConsumerStatefulWidget {
  const SecurityPulseApp({super.key});

  @override
  ConsumerState<SecurityPulseApp> createState() => _SecurityPulseAppState();
}

class _SecurityPulseAppState extends ConsumerState<SecurityPulseApp> {
  late final _AuthChangeNotifier _authChangeNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authChangeNotifier = _AuthChangeNotifier();
    _router = createAppRouter(
      isAuthenticated: _isAuthenticated,
      refreshListenable: _authChangeNotifier,
    );
  }

  @override
  void dispose() {
    _authChangeNotifier.dispose();
    super.dispose();
  }

  bool _isAuthenticated() {
    final state = ref.read(authProvider);
    return state is AuthAuthenticated;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes and notify the router.
    ref.listen<AuthState>(authProvider, (previous, next) {
      _authChangeNotifier.notify();
    });

    return MaterialApp.router(
      title: 'Security Pulse',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        // Additional locales added per governance decision #7
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}

/// A [ChangeNotifier] that triggers GoRouter refresh on auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}
