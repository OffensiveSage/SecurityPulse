/// Sign-in screen.
///
/// Displays the corporate sign-in button and app identity.
/// On tap, initiates the OIDC sign-in flow via the auth provider.
///
/// Accessibility:
/// - The sign-in button has a clear label describing the action.
/// - The screen is announced by screen readers on navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: switch (authState) {
        AuthLoading() => LoadingView(message: l10n.signInLoading),
        AuthError(:final failure) => ErrorView(
            failure: failure,
            onRetry: ref.read(authProvider.notifier).dismissError,
          ),
        _ => _buildSignInBody(context, ref, l10n),
      },
    );
  }

  Widget _buildSignInBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App identity
            Icon(
              Icons.security_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
              semanticLabel: l10n.appName,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.appName,
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.signInSubtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Sign-in button
            Semantics(
              button: true,
              label: l10n.signInButtonLabel,
              child: FilledButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).signIn();
                },
                icon: const Icon(Icons.business_rounded),
                label: Text(l10n.signInButtonLabel),
              ),
            ),

            const SizedBox(height: 16),

            // Privacy note
            Text(
              l10n.signInPrivacyNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
