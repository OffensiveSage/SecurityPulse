/// Security Pulse — application entry point.
///
/// Initializes the dependency injection container before running the app.
/// Wraps the app in [ProviderScope] for Riverpod state management.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait by default; tablet layouts (Phase 7) may relax this
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Phase 2: Add get_it setup here.

  runApp(const ProviderScope(child: SecurityPulseApp()));
}
