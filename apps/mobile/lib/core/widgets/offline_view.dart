/// OfflineView — displayed when the device has no network connectivity.
library;

import 'package:flutter/material.dart';

import 'error_view.dart';
import '../error/failures.dart';

class OfflineView extends StatelessWidget {
  const OfflineView({
    super.key,
    this.onRetry,
  });

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      failure: const NetworkFailure(),
      onRetry: onRetry,
    );
  }
}
