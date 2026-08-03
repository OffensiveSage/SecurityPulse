/// UnauthorizedView — displayed when the user lacks permission.
///
/// Does not reveal why access was denied (security principle of
/// minimal information disclosure).
library;

import 'package:flutter/material.dart';

import 'error_view.dart';
import '../error/failures.dart';

class UnauthorizedView extends StatelessWidget {
  const UnauthorizedView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ErrorView(
      failure: UnauthorizedFailure(),
    );
  }
}
