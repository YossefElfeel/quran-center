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
import '../../features/documents/presentation/screens/certificate_preview_screen.dart';
import '../../features/enrollment/presentation/screens/circle_roster_screen.dart';
import '../../features/excuse/presentation/screens/excuse_queue_screen.dart';
import '../../features/family/presentation/screens/guardian_links_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/intake/presentation/screens/waiting_list_screen.dart';
import '../../features/monthly/presentation/screens/monthly_plan_editor_screen.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/parent_portal/presentation/screens/child_card_screen.dart';
import '../../features/parent_portal/presentation/screens/children_screen.dart';
import '../../features/session/presentation/screens/my_circles_screen.dart';
import '../../features/session/presentation/screens/today_session_screen.dart';
import '../../features/subscription/presentation/screens/household_members_screen.dart';
import '../../features/subscription/presentation/screens/subscriptions_screen.dart';
import '../../features/supervisor_eval/presentation/screens/attention_screen.dart';
import '../../features/supervisor_eval/presentation/screens/circle_eval_screen.dart';
import '../../features/supervisor_eval/presentation/screens/eval_circles_screen.dart';
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
        path: Routes.notifications,
        builder: (BuildContext context, GoRouterState state) =>
            const NotificationListScreen(),
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
      GoRoute(
        path: Routes.adminSubscriptions,
        builder: (BuildContext context, GoRouterState state) =>
            const SubscriptionsScreen(),
      ),
      GoRoute(
        path: Routes.adminGuardians,
        builder: (BuildContext context, GoRouterState state) =>
            const GuardianLinksScreen(),
      ),
      GoRoute(
        path: Routes.householdMembersPattern,
        builder: (BuildContext context, GoRouterState state) =>
            HouseholdMembersScreen(
              householdId: state.pathParameters['householdId']!,
              householdName: state.uri.queryParameters['name'] ?? 'الأسرة',
            ),
      ),
      GoRoute(
        path: Routes.teacherCircles,
        builder: (BuildContext context, GoRouterState state) =>
            const MyCirclesScreen(),
      ),
      GoRoute(
        path: Routes.sessionPattern,
        builder: (BuildContext context, GoRouterState state) =>
            TodaySessionScreen(
              circleId: state.pathParameters['circleId']!,
              circleName: state.uri.queryParameters['name'] ?? 'الحلقة',
            ),
      ),
      GoRoute(
        path: Routes.monthlyPlanPattern,
        builder: (BuildContext context, GoRouterState state) =>
            MonthlyPlanEditorScreen(
              circleId: state.pathParameters['circleId']!,
              circleName: state.uri.queryParameters['name'] ?? 'الحلقة',
            ),
      ),
      GoRoute(
        path: Routes.supervisorEval,
        builder: (BuildContext context, GoRouterState state) =>
            const EvalCirclesScreen(),
      ),
      GoRoute(
        path: Routes.supervisorExcuses,
        builder: (BuildContext context, GoRouterState state) =>
            const ExcuseQueueScreen(),
      ),
      GoRoute(
        path: Routes.supervisorAttention,
        builder: (BuildContext context, GoRouterState state) =>
            const AttentionScreen(),
      ),
      GoRoute(
        path: Routes.parentChildren,
        builder: (BuildContext context, GoRouterState state) =>
            const ChildrenScreen(),
      ),
      GoRoute(
        path: Routes.parentChildPattern,
        builder: (BuildContext context, GoRouterState state) => ChildCardScreen(
          studentPersonId: state.pathParameters['studentId']!,
          childName: state.uri.queryParameters['name'] ?? 'الطفل',
        ),
      ),
      GoRoute(
        path: Routes.certificatePreviewPattern,
        builder: (BuildContext context, GoRouterState state) =>
            CertificatePreviewScreen(
              studentName: state.uri.queryParameters['name'] ?? 'الطالب',
              kindLabel: state.uri.queryParameters['kind'] ?? 'شهادة',
              dateLabel: state.uri.queryParameters['date'] ?? '',
            ),
      ),
      GoRoute(
        path: Routes.supervisorCircleEvalPattern,
        builder: (BuildContext context, GoRouterState state) =>
            CircleEvalScreen(
              circleId: state.pathParameters['circleId']!,
              circleName: state.uri.queryParameters['name'] ?? 'الحلقة',
            ),
      ),
    ],
  );
}
