/// Guest welcome screen for Personal mode.
///
/// Shown after the user selects Personal mode. Lets them start
/// exploring without creating an account, or sign in with an
/// existing Work account.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../providers/app_mode_provider.dart';

class GuestWelcomeScreen extends ConsumerWidget {
  const GuestWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // ── Hero ──────────────────────────────────────────────────────
              Semantics(
                label: '',
                child: Icon(
                  Icons.shield_rounded,
                  size: 72,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.guestWelcomeTitle,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.guestWelcomeSubtitle,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // ── Actions ───────────────────────────────────────────────────
              FilledButton(
                onPressed: () async {
                  await ref.read(appModeProvider.notifier).setGuestMode();
                  if (context.mounted) {
                    context.goNamed(RouteNames.home);
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.guestStartButton),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.goNamed(RouteNames.signIn),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.guestSignInLink),
              ),

              const SizedBox(height: 24),

              // ── Privacy note ──────────────────────────────────────────────
              Text(
                l10n.guestPrivacyNote,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
