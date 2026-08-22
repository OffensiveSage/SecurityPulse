/// Scenario shell screen — Phase 1 placeholder.
///
/// Phase 3 replaces this with the actual daily scenario flow.
library;

import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_view.dart';

class ScenarioShellScreen extends StatelessWidget {
  const ScenarioShellScreen({super.key, this.scenarioId});

  final String? scenarioId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Pulse')),
      body: EmptyView(
        title: scenarioId != null
            ? 'Scenario not yet loaded'
            : 'No question today',
        message: 'Phase 3 will implement the daily scenario flow.',
        icon: Icons.quiz_rounded,
      ),
    );
  }
}
