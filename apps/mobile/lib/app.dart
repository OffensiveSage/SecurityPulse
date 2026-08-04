/// Application root widget.
///
/// Sets up:
/// - GoRouter for navigation and deep links
/// - MaterialApp with light and dark themes
/// - Localization delegates
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class SecurityPulseApp extends StatefulWidget {
  const SecurityPulseApp({super.key});

  @override
  State<SecurityPulseApp> createState() => _SecurityPulseAppState();
}

class _SecurityPulseAppState extends State<SecurityPulseApp> {
  late final _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Security Pulse',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _router,
      localizationsDelegates: const [
        // Generated delegate — run `flutter gen-l10n` to create
        // AppLocalizations.delegate,
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
