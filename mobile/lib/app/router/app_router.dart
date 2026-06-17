import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/auth/go_router_refresh_stream.dart';
import '../../features/admin_setup/presentation/screens/circles_screen.dart';
import '../../features/admin_setup/presentation/screens/curricula_screen.dart';
import '../../features/admin_setup/presentation/screens/levels_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/enrollment/presentation/screens/circle_roster_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/intake/presentation/screens/waiting_list_screen.dart';
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
      GoRoute(
        path: Routes.adminCurricula,
        builder: (BuildContext context, GoRouterState state) =>
            const CurriculaScreen(),
      ),
      GoRoute(
        path: Routes.levelsPattern,
        builder: (BuildContext context, GoRouterState state) => LevelsScreen(
          curriculumId: state.pathParameters['curriculumId']!,
          curriculumName: state.uri.queryParameters['name'] ?? 'المنهج',
        ),
      ),
      GoRoute(
        path: Routes.circlesPattern,
        builder: (BuildContext context, GoRouterState state) => CirclesScreen(
          levelId: state.pathParameters['levelId']!,
          levelName: state.uri.queryParameters['name'] ?? 'المستوى',
        ),
      ),
      GoRoute(
        path: Routes.rosterPattern,
        builder: (BuildContext context, GoRouterState state) =>
            CircleRosterScreen(
          circleId: state.pathParameters['circleId']!,
          circleName: state.uri.queryParameters['name'] ?? 'الحلقة',
        ),
      ),
      GoRoute(
        path: Routes.adminWaiting,
        builder: (BuildContext context, GoRouterState state) =>
            const WaitingListScreen(),
      ),
    ],
  );
}
