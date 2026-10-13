import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/parent_gate.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/shell/sync_status_sheet.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/settings/settings_repository.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/sync/outbox_store.dart';
import '../../../../core/sync/sync_status_provider.dart';
import '../../../../core/utils/arabic_date.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_icons.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_search_picker.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../admin_setup/domain/circle.dart';
import '../../../enrollment/presentation/widgets/enroll_student_flow.dart';
import '../../../excuse/presentation/controllers/pending_excuses_controller.dart';
import '../../../intake/presentation/controllers/waiting_list_controller.dart';
import '../../../monthly/presentation/controllers/monthly_eval_controllers.dart';
import '../../../parent_portal/domain/child_card.dart';
import '../../../parent_portal/domain/child_summary.dart';
import '../../../parent_portal/presentation/controllers/child_card_controller.dart';
import '../../../parent_portal/presentation/controllers/my_children_controller.dart';
import '../../../session/domain/roster_entry.dart';
import '../../../session/presentation/controllers/my_circles_controller.dart';
import '../../../session/presentation/controllers/today_session_controller.dart';
import '../../../subscription/data/subscription_repository.dart';
import '../../../subscription/domain/household_summary.dart';
import '../../../subscription/presentation/controllers/households_controller.dart';
import '../../../subscription/presentation/controllers/my_subscription_controller.dart';
import '../../../subscription/presentation/widgets/record_payment_sheet.dart';
import '../../../supervisor_eval/presentation/controllers/eval_circles_controller.dart';
import '../../../supervisor_eval/presentation/controllers/struggling_controller.dart';
import '../../../teacher/presentation/controllers/teacher_controllers.dart';

/// هامش أفقي واحد لكل أقسام الهوم (بيطابق هامش [AppListCard]/[AppSectionHeader]).
const EdgeInsets _hPad = EdgeInsets.symmetric(horizontal: AppSpacing.md);

final FutureProvider<String> homeNameProvider = FutureProvider((Ref ref) async {
  final String? id = await ref.watch(currentPersonIdProvider.future);
  if (id == null) return '';
  final Map<String, dynamic>? person = await ref
      .watch(supabaseClientProvider)
      .from('person')
      .select('full_name')
      .eq('id', id)
      .maybeSingle();
  return (person?['full_name'] as String? ?? '').split(' ').first;
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<String>> roles = ref.watch(currentRolesProvider);
    final String name = ref.watch(homeNameProvider).asData?.value ?? '';
    final AppSettings settings =
        ref.watch(appSettingsProvider).asData?.value ?? AppSettings.defaults;
    final DateTime today = DateTime.now();
    final HijriCalendar hijri = HijriCalendar.fromDate(today);
    return Scaffold(
      body: SafeArea(
        child: roles.when(
          loading: () => const AppListSkeleton(),
          error: (_, _) => AppErrorView(
            message: l.homeAccountLoadError,
            onRetry: () => ref.invalidate(currentRolesProvider),
          ),
          data: (List<String> roles) => AppRefreshIndicator(
            onRefresh: () async {
              ref.invalidate(homeNameProvider);
              ref.invalidate(myCirclesProvider);
              ref.invalidate(myChildrenProvider);
              ref.invalidate(overdueHouseholdsProvider);
              ref.invalidate(mySubscriptionActiveProvider);
              ref.invalidate(pendingMonthlyEvalsProvider);
              ref.invalidate(pendingDevelopmentProvider);
              ref.invalidate(pendingExcusesControllerProvider);
              ref.invalidate(strugglingStudentsProvider);
              ref.invalidate(waitingListControllerProvider);
              ref.invalidate(evalCirclesProvider);
              ref.invalidate(evalMonthProgressProvider);
            },
            child: ListView(
              // هامش أفقي واحد لكل الأقسام: الكروت/العناوين بتحطّ هامشها
              // (md)، والنصوص والأزرار بتتلف في [_hPad] بنفس القيمة.
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              children: <Widget>[
                Padding(
                  padding: _hPad,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name.isEmpty ? l.welcome : l.homeGreeting(name),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(settings.centerName),
                      Text(
                        l.homeDateLine(
                          arabicNumber(today.day),
                          arabicMonthLabel(today),
                          arabicNumber(hijri.hDay),
                          arabicNumber(hijri.hMonth),
                          arabicNumber(hijri.hYear),
                        ),
                        style: TextStyle(color: context.palette.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (roles.contains('teacher')) ...<Widget>[
                  AppSectionHeader(title: l.homeTodaySessions),
                  ref
                      .watch(myCirclesProvider)
                      .when(
                        loading: () => const _Loading(),
                        error: (_, _) => _Retry(
                          message: l.homeCirclesLoadError,
                          onRetry: () => ref.invalidate(myCirclesProvider),
                        ),
                        data: (List<Circle> circles) => Column(
                          children: <Widget>[
                            if (circles.isEmpty)
                              Padding(
                                padding: _hPad,
                                child: Text(l.homeNoCircleAssigned),
                              ),
                            for (final Circle circle in circles)
                              _TeacherCircle(circle: circle),
                          ],
                        ),
                      ),
                  const _SyncButton(),
                ],
                if (roles.contains('parent')) ...<Widget>[
                  AppSectionHeader(title: l.homeFollowChildren),
                  ref
                      .watch(myChildrenProvider)
                      .when(
                        loading: () => const _Loading(),
                        error: (_, _) => _Retry(
                          message: l.homeChildrenLoadError,
                          onRetry: () => ref.invalidate(myChildrenProvider),
                        ),
                        data: (List<ChildSummary> children) => Column(
                          children: <Widget>[
                            if (children.isEmpty)
                              AppListCard(
                                title: l.homeContactAdminToLinkChildren,
                                onTap: () =>
                                    context.push('/parent/subscription'),
                              ),
                            for (final ChildSummary child in children)
                              _HomeChild(child: child),
                          ],
                        ),
                      ),
                  // الاشتراك قسم لوحده (مش وسط ملخّصات الولاد).
                  AppSectionHeader(title: l.fySubscriptionSection),
                  const _MySubscriptionCard(),
                ],
                if (roles.any(
                  (String r) => <String>['admin', 'super_admin'].contains(r),
                )) ...<Widget>[
                  AppSectionHeader(title: l.homeCenterManagement),
                  Padding(
                    padding: _hPad,
                    child: Column(
                      children: <Widget>[
                        AppButton(
                          label: l.enrEnrollStudent,
                          icon: Icons.person_add,
                          onPressed: () => enrollStudentFlow(context, ref),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: l.homeRecordPayment,
                          icon: Icons.payments,
                          variant: AppButtonVariant.outlined,
                          onPressed: () => _recordPaymentFlow(context, ref),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                  _Queue(
                    state: ref.watch(waitingListControllerProvider),
                    title: l.navWaitingList,
                    route: Routes.adminWaiting,
                    alwaysShow: true,
                  ),
                  AppSectionHeader(title: l.homeOverdueSubscriptions),
                  ref
                      .watch(overdueHouseholdsProvider)
                      .when(
                        loading: () => const _Loading(),
                        error: (_, _) => _Retry(
                          message: l.homeSubscriptionsLoadError,
                          onRetry: () =>
                              ref.invalidate(overdueHouseholdsProvider),
                        ),
                        data: (List<HouseholdSummary> households) => Column(
                          children: <Widget>[
                            if (households.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                child: Text(l.homeNoOverdueSubscriptions),
                              ),
                            for (final HouseholdSummary h in households)
                              AppListCard(
                                title: h.name,
                                subtitle: _overdueLine(l, h, today),
                                onTap: () => context.push(
                                  Routes.householdMembers(h.id, h.name),
                                ),
                              ),
                          ],
                        ),
                      ),
                ],
                if (roles.any(
                  (String r) => <String>[
                    'supervisor',
                    'admin',
                    'super_admin',
                  ].contains(r),
                )) ...<Widget>[
                  if (roles.contains('supervisor')) const _SupervisorCircles(),
                  AppSectionHeader(title: l.homeNeedsYourDecision),
                  _Queue(
                    state: ref.watch(pendingExcusesControllerProvider),
                    title: l.homeAbsenceExcuses,
                    route: Routes.supervisorExcuses,
                  ),
                  _Queue(
                    state: ref.watch(pendingMonthlyEvalsProvider),
                    title: l.homeMonthlyEvals,
                    route: Routes.supervisorMonthlyEval,
                  ),
                  _Queue(
                    state: ref.watch(pendingDevelopmentProvider),
                    title: l.navTeacherDev,
                    route: Routes.supervisorDevApproval,
                  ),
                ],
                // `/supervisor/attention` بيستدعي RPC للمشرف — مش للمعلّم لوحده.
                if (roles.any(
                  (String r) => <String>[
                    'supervisor',
                    'admin',
                    'super_admin',
                  ].contains(r),
                ))
                  _Queue(
                    state: ref.watch(strugglingStudentsProvider),
                    title: l.homeStrugglingStudents,
                    route: Routes.supervisorAttention,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Queue<T> extends StatelessWidget {
  const _Queue({
    required this.state,
    required this.title,
    required this.route,
    this.alwaysShow = false,
  });
  final AsyncValue<List<T>> state;
  final String title, route;
  final bool alwaysShow;
  @override
  Widget build(BuildContext context) => state.when(
    loading: () => const _Loading(),
    error: (_, _) => Padding(
      padding: _hPad,
      child: Text(AppL10n.of(context).homeQueueLoadError(title)),
    ),
    data: (List<T> rows) => rows.isEmpty && !alwaysShow
        ? const SizedBox.shrink()
        : AppListCard(
            title:
                '$title (${arabicNumber(rows.length)}${rows.length >= 50 ? '+' : ''})',
            onTap: () => context.push(route),
          ),
  );
}

/// مؤشّر تحميل بنفس هامش الأقسام.
class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    child: LinearProgressIndicator(),
  );
}

/// سطر الأسرة المتأخّرة: "متأخر ٤ شهور · ٤٠٠ ج.م" (أو الشهري لو مفيش دفعات).
String _overdueLine(AppL10n l, HouseholdSummary h, DateTime today) {
  final int? months = h.monthsLate(today);
  if (months == null || months <= 0) {
    return l.homeMonthlyAmount(arabicAmount(h.monthlyAmount));
  }
  return l.fyOverdueSummary(
    l.fyMonthsCount(months, arabicNumber(months)),
    arabicAmount(h.amountDue(today)),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(message),
    trailing: TextButton(
      onPressed: onRetry,
      child: Text(AppL10n.of(context).retry),
    ),
  );
}

/// "تسجيل دفعة" من الهوم: اختيار الأسرة (بحث) ← شيت الدفعة.
Future<void> _recordPaymentFlow(BuildContext context, WidgetRef ref) async {
  final AppL10n l = AppL10n.of(context);
  final SubscriptionRepository repo = ref.read(subscriptionRepositoryProvider);
  final HouseholdSummary? household =
      await showAppServerSearchPicker<HouseholdSummary>(
        context: context,
        title: l.homePickHousehold,
        searchLabel: l.homeSearchHouseholdName,
        search: (String q) => repo.fetchHouseholds(query: q),
        label: (HouseholdSummary h) => h.name,
      );
  if (household == null || !context.mounted) return;
  await showAppModalSheet<void>(
    context: context,
    title: l.homeRecordPayment,
    builder: (_) =>
        RecordPaymentSheet(household: household, feedbackContext: context),
  );
  if (context.mounted) ref.invalidate(overdueHouseholdsProvider);
}

/// زرار حالة المزامنة للمعلّم + عدد العمليات المعلّقة (لو فيه).
class _SyncButton extends ConsumerWidget {
  const _SyncButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final SyncStatus? status = ref.watch(syncStatusProvider).asData?.value;
    final int pending = status?.pending ?? 0;
    final bool failed = status?.hasFailures ?? false;
    final String label = pending > 0
        ? l.homeSyncPendingSemantics(arabicNumber(pending))
        : failed
        ? l.homeSyncFailedSemantics
        : l.syncStatusTitle;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: TextButton.icon(
            onPressed: () => SyncStatusSheet.show(context),
            icon: Badge(
              isLabelVisible: pending > 0 || failed,
              backgroundColor: failed ? context.palette.error : null,
              label: Text(pending > 0 ? arabicNumber(pending) : '!'),
              child: const Icon(Icons.sync),
            ),
            label: Text(
              pending > 0
                  ? l.homeSyncPendingLabel(arabicNumber(pending))
                  : l.syncStatusTitle,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeChild extends ConsumerWidget {
  const _HomeChild({required this.child});
  final ChildSummary child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    // الاشتراك على مستوى الأسرة — نفس الحالة لكل طفل في نفس الحساب.
    final bool? subscribed = ref
        .watch(mySubscriptionActiveProvider)
        .asData
        ?.value;
    if (subscribed == false) return HomeLockedChildCard(child: child);
    final AsyncValue<ChildCard> state = ref.watch(
      childCardProvider(child.studentPersonId),
    );
    return AppListCard(
      title: child.fullName,
      leadingIcon: Icons.child_care,
      subtitle: state.when(
        loading: () => l.homeLoadingProgress,
        error: (_, _) => l.homeProgressLoadError,
        data: (ChildCard card) {
          final String? portion = card.currentPortion;
          final String portionLine = portion == null || portion.trim().isEmpty
              ? l.homeNoPortion
              : l.homeCurrentPortion(portion);
          final int total =
              card.present + card.late + card.absent + card.excused;
          final String attendance = total == 0
              ? l.fyNoSessionsThisMonth
              : l.homeMonthAttendance(
                  arabicNumber(card.present + card.late),
                  arabicNumber(total),
                );
          return '$portionLine\n$attendance';
        },
      ),
      trailing: subscribed == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppStatusBadge(
                  label: l.homeSubscriptionActive,
                  kind: AppStatusKind.success,
                ),
                Icon(AppIcons.drillIn, color: context.palette.textSecondary),
              ],
            ),
      onTap: () => context.push(
        Routes.parentChild(child.studentPersonId, child.fullName),
      ),
    );
  }
}

/// كارت طفل والاشتراك مش نشط: الاسم + "التفاصيل متاحة بعد تجديد الاشتراك"
/// من غير ملخّص (ورد/حضور)، والنقر بيفتح شاشة الاشتراك مع اسم الطفل.
class HomeLockedChildCard extends StatelessWidget {
  const HomeLockedChildCard({required this.child, super.key});
  final ChildSummary child;
  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return AppListCard(
      title: child.fullName,
      leadingIcon: AppIcons.locked,
      iconColor: p.textSecondary,
      subtitle: l.fyChildLockedLine,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppStatusBadge(
            label: l.homeSubscriptionOverdue,
            kind: AppStatusKind.warning,
          ),
          Icon(AppIcons.drillIn, color: p.textSecondary),
        ],
      ),
      onTap: () => context.push(
        parentSubscriptionGateLocation(childName: child.fullName),
      ),
    );
  }
}

/// كارت "اشتراكي" في قسم الاشتراك — بحالته (ساري/متأخّر) لو معروفة.
class _MySubscriptionCard extends ConsumerWidget {
  const _MySubscriptionCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final bool? subscribed = ref
        .watch(mySubscriptionActiveProvider)
        .asData
        ?.value;
    return AppListCard(
      title: l.homeMySubscription,
      leadingIcon: Icons.payments_outlined,
      iconColor: subscribed == false ? context.palette.warning : null,
      subtitle: subscribed == null
          ? null
          : subscribed
          ? l.homeSubscriptionActive
          : l.homeSubscriptionOverdue,
      onTap: () => context.push(parentSubscriptionRoute),
    );
  }
}

/// ملخّص الحلقات للمشرف: كل حلقة بمعلّمها وتقدّم تقييم الشهر ده
/// (اتقيّم كام من كام) + "عرض الكل" للمراجعات.
class _SupervisorCircles extends ConsumerWidget {
  const _SupervisorCircles();

  static const int _maxRows = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final Map<String, int> progress =
        ref.watch(evalMonthProgressProvider).asData?.value ??
        const <String, int>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: l.fyHomeCirclesSection,
          action: TextButton(
            onPressed: () => context.go(Routes.primaryTab),
            child: Text(l.fyHomeShowAll),
          ),
        ),
        ref
            .watch(evalCirclesProvider)
            .when(
              loading: () => const _Loading(),
              error: (_, _) => _Retry(
                message: l.supCirclesLoadError,
                onRetry: () => ref.invalidate(evalCirclesProvider),
              ),
              data: (List<Circle> circles) => Column(
                children: <Widget>[
                  if (circles.isEmpty)
                    Padding(padding: _hPad, child: Text(l.supNoCircles)),
                  for (final Circle c in circles.take(_maxRows))
                    AppListCard(
                      title: c.name,
                      leadingIcon: Icons.fact_check,
                      subtitle: _subtitle(l, c, progress[c.id] ?? 0),
                      onTap: () => context.push(
                        Routes.supervisorCircleEval(c.id, c.name),
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }

  String? _subtitle(AppL10n l, Circle c, int evaluated) {
    final String? teacher = c.teacherName;
    final int? total = c.activeStudentCount;
    final String? line = total == null
        ? null
        : evaluated == 0
        ? l.fyHomeCircleEvalNone(
            l.enrCircleStudentCount(total, arabicNumber(total)),
          )
        : l.fyHomeCircleEvalProgress(
            arabicNumber(evaluated),
            arabicNumber(total),
          );
    if (teacher == null || teacher.isEmpty) return line;
    if (line == null) return teacher;
    return l.fyHomeCircleSubtitle(teacher, line);
  }
}

/// كارت حلقة في الهوم — بيودّي لشاشة الحصة بس؛ فتح الحصة نفسه قرار المعلّم
/// من جوّه الشاشة (مش side effect للنقر هنا).
class _TeacherCircle extends ConsumerWidget {
  const _TeacherCircle({required this.circle});
  final Circle circle;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<TodaySession> state = ref.watch(
      todaySessionControllerProvider(circle.id),
    );
    return AppListCard(
      title: circle.name,
      leadingIcon: Icons.menu_book,
      subtitle: state.when(
        loading: () => l.homeLoadingSession,
        error: (_, _) => l.homeSessionLoadError,
        data: (TodaySession s) => s.isOpen
            ? l.homeSessionOpen
            : s.closedToday
            ? l.homeSessionClosed(
                arabicNumber(s.presentCount),
                arabicNumber(s.tasmeeCount),
              )
            : l.homeSessionNotOpened,
      ),
      onTap: () => context.push<void>(Routes.session(circle.id, circle.name)),
    );
  }
}
