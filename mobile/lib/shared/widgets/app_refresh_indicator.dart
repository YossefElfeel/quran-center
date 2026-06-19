import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// غلاف pull-to-refresh موحّد بلون العلامة.
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: p.primary,
      backgroundColor: p.surface,
      child: child,
    );
  }
}
