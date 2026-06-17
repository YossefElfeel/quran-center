import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/auth/go_router_refresh_stream.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// راوتر التطبيق (go_router) — keepAlive، وبيعيد التقييم مع تغيّر الجلسة.
/// غير مسجّل → /login ؛ مسجّل وفاتح /login → / .
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final AuthRepository auth = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: GoRouterRefreshStream(auth.authStateChanges),
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = auth.currentSession != null;
      final bool loggingIn = state.matchedLocation == Routes.login;
      if (!loggedIn) return loggingIn ? null : Routes.login;
      if (loggingIn) return Routes.home;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.home,
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
    ],
  );
}
