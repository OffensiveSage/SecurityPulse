/// Settings shell screen — Phase 1 placeholder.
library;

import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_view.dart';

class SettingsShellScreen extends StatelessWidget {
  const SettingsShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const EmptyView(
        title: 'Settings',
        message: 'Notification preferences and accessibility options will appear here.',
        icon: Icons.settings_rounded,
      ),
    );
  }
}
