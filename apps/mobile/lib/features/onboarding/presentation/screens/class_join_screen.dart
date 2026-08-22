/// Class join screen for School mode.
///
/// Users select their role (Student or Teacher) and enter a class code
/// to join their classroom. Any non-empty code of 3–20 characters is
/// accepted in demo mode. Data is stored in SharedPreferences.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../providers/app_mode_provider.dart';

class ClassJoinScreen extends ConsumerStatefulWidget {
  const ClassJoinScreen({super.key});

  @override
  ConsumerState<ClassJoinScreen> createState() => _ClassJoinScreenState();
}

class _ClassJoinScreenState extends ConsumerState<ClassJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  SchoolRole _selectedRole = SchoolRole.student;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinClass() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    await ref.read(schoolRoleProvider.notifier).setRole(_selectedRole);
    await ref
        .read(classCodeProvider.notifier)
        .setCode(_codeController.text.trim());

    if (mounted) {
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed(RouteNames.modeSelector),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Icon + title ─────────────────────────────────────────
                Semantics(
                  label: '',
                  child: Icon(
                    Icons.school_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.classJoinTitle,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // ── Role selector ────────────────────────────────────────
                Text(
                  'I am a…',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<SchoolRole>(
                  segments: [
                    ButtonSegment(
                      value: SchoolRole.student,
                      label: Text(l10n.classJoinRoleStudent),
                      icon: const Icon(Icons.person_rounded),
                    ),
                    ButtonSegment(
                      value: SchoolRole.teacher,
                      label: Text(l10n.classJoinRoleTeacher),
                      icon: const Icon(Icons.co_present_rounded),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedRole = selection.first);
                  },
                ),
                const SizedBox(height: 24),

                // ── Class code field ─────────────────────────────────────
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.classJoinCodeLabel,
                    hintText: l10n.classJoinCodeHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.tag_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.classJoinValidationRequired;
                    }
                    if (value.trim().length < 3 || value.trim().length > 20) {
                      return l10n.classJoinValidationLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Join button ──────────────────────────────────────────
                FilledButton(
                  onPressed: _isSubmitting ? null : _joinClass,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.classJoinButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
