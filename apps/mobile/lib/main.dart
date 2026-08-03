/// Security Pulse — application entry point.
///
/// Initializes the dependency injection container before running the app.
/// Phase 2 will add ProviderScope for Riverpod here.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait by default; tablet layouts (Phase 7) may relax this
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Phase 1: No DI initialization yet.
  // Phase 2: Add get_it setup and ProviderScope here.

  runApp(const SecurityPulseApp());
}
