/// Profile shell screen — Phase 1 placeholder.
library;

import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_view.dart';

class ProfileShellScreen extends StatelessWidget {
  const ProfileShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const EmptyView(
        title: 'Profile',
        message: 'Phase 2 will implement the employee profile screen.',
        icon: Icons.person_rounded,
      ),
    );
  }
}
