/// Sign-in screen — Phase 1 shell.
///
/// This screen shows the OIDC sign-in button.
/// Phase 2 implements the actual flutter_appauth integration.
///
/// Accessibility:
/// - The sign-in button has a clear label describing the action.
/// - The screen is announced by screen readers on navigation.
library;

import 'package:flutter/material.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                semanticLabel: 'Security Pulse',
              ),
              const SizedBox(height: 16),
              Text(
                'Security Pulse',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Corporate cybersecurity awareness',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Sign-in button — Phase 2 implements OIDC
              FilledButton.icon(
                onPressed: () {
                  // TODO(phase-2): Implement OIDC sign-in via flutter_appauth
                },
                icon: const Icon(Icons.business_rounded),
                label: const Text('Sign in with your company account'),
              ),

              const SizedBox(height: 16),

              // Privacy note
              Text(
                'By signing in you agree to your organisation\'s '
                'acceptable use policy.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
