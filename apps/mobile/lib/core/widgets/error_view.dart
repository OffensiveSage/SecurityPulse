/// ErrorView — displayed when an operation fails.
///
/// Accessibility:
/// - Uses Semantics with liveRegion so screen readers announce errors.
/// - The retry button has a clear accessible label.
library;

import 'package:flutter/material.dart';

import '../error/failures.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.failure,
    this.onRetry,
  });

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final String title = _titleFor(context, failure);
    final String message = _messageFor(failure);

    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconFor(failure),
                size: 48,
                color: Theme.of(context).colorScheme.error,
                semanticLabel: title,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _titleFor(BuildContext context, Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'No connection',
      UnauthenticatedFailure() => 'Sign in required',
      UnauthorizedFailure() => 'Access denied',
      NotFoundFailure() => 'Not found',
      _ => 'Something went wrong',
    };
  }

  static String _messageFor(Failure failure) => failure.message;

  static IconData _iconFor(Failure failure) {
    return switch (failure) {
      NetworkFailure() => Icons.wifi_off_rounded,
      UnauthenticatedFailure() => Icons.lock_outline_rounded,
      UnauthorizedFailure() => Icons.block_rounded,
      NotFoundFailure() => Icons.search_off_rounded,
      _ => Icons.error_outline_rounded,
    };
  }
}
