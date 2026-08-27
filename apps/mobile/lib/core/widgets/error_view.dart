/// ErrorView — displayed when an operation fails.
///
/// Accessibility:
/// - Uses Semantics with liveRegion so screen readers announce errors.
/// - The retry button has a clear accessible label.
library;

import 'package:flutter/material.dart';

import '../error/failures.dart';
import '../l10n/app_localizations.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.failure,
    super.key,
    this.onRetry,
  });

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String title = _titleFor(l10n, failure);
    final String message = _messageFor(l10n, failure);

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
                  child: Text(l10n.buttonRetry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _titleFor(AppLocalizations l10n, Failure failure) {
    return switch (failure) {
      NetworkFailure() => l10n.errorNetworkTitle,
      UnauthenticatedFailure() => l10n.errorUnauthenticatedTitle,
      UnauthorizedFailure() => l10n.errorUnauthorizedTitle,
      NotFoundFailure() => l10n.errorNotFoundTitle,
      _ => l10n.errorGenericTitle,
    };
  }

  static String _messageFor(AppLocalizations l10n, Failure failure) {
    return switch (failure) {
      NetworkFailure() => l10n.errorNetworkMessage,
      UnauthenticatedFailure() => l10n.errorUnauthenticatedMessage,
      UnauthorizedFailure() => l10n.errorUnauthorizedMessage,
      NotFoundFailure() => l10n.errorNotFoundMessage,
      _ => failure.message,
    };
  }

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
