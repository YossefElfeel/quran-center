import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';

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
import '../../../supervisor_eval/presentation/controllers/struggling_controller.dart';
import '../../../teacher/presentation/controllers/teacher_controllers.dart';

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
            message: 'تعذّر تحميل حسابك',
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
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                Text(
                  name.isEmpty ? 'أهلاً بيك' : 'أهلاً يا $name',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(settings.centerName),
                Text(
                  '${arabicNumber(today.day)} ${arabicMonthLabel(today)} · ${arabicNumber(hijri.hDay)}/${arabicNumber(hijri.hMonth)}/${arabicNumber(hijri.hYear)} هـ',
                  style: TextStyle(color: context.palette.textSecondary),
                ),
                const SizedBox(height: 24),
                if (roles.contains('teacher')) ...<Widget>[
                  const AppSectionHeader(title: 'حصص النهارده'),
                  ref
                      .watch(myCirclesProvider)
                      .when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => _Retry(
                          message: 'تعذّر تحميل الحلقات',
                          onRetry: () => ref.invalidate(myCirclesProvider),
                        ),
                        data: (List<Circle> circles) => Column(
                          children: <Widget>[
                            if (circles.isEmpty)
                              const Text(
                                'لسه مفيش حلقة مرتبطة بيك — كلّم الإدارة لإسناد حلقة',
                              ),
                            for (final Circle circle in circles)
                              _TeacherCircle(circle: circle),
                          ],
                        ),
                      ),
                  const _SyncButton(),
                ],
                if (roles.contains('parent')) ...<Widget>[
                  const AppSectionHeader(title: 'متابعة ولادك'),
                  AppListCard(
                    title: 'اشتراكي',
                    leadingIcon: Icons.payments_outlined,
                    onTap: () => context.push('/parent/subscription'),
                  ),
                  ref
                      .watch(myChildrenProvider)
                      .when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => _Retry(
                          message: 'تعذّر تحميل الأطفال',
                          onRetry: () => ref.invalidate(myChildrenProvider),
                        ),
                        data: (List<ChildSummary> children) => Column(
                          children: <Widget>[
                            if (children.isEmpty)
                              AppListCard(
                                title: 'كلّم الإدارة لربط ولادك',
                                onTap: () =>
                                    context.push('/parent/subscription'),
                              ),
                            for (final ChildSummary child in children)
                              _HomeChild(child: child),
                          ],
                        ),
                      ),
                ],
                if (roles.any(
                  (String r) => <String>['admin', 'super_admin'].contains(r),
                )) ...<Widget>[
                  const AppSectionHeader(title: 'إدارة الدار'),
                  AppButton(
                    label: 'تسجيل طالب',
                    icon: Icons.person_add,
                    onPressed: () => enrollStudentFlow(context, ref),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'تسجيل دفعة',
                    icon: Icons.payments,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => _recordPaymentFlow(context, ref),
                  ),
                  _Queue(
                    state: ref.watch(waitingListControllerProvider),
                    title: 'قائمة الانتظار',
                    route: Routes.adminWaiting,
                    alwaysShow: true,
                  ),
                  const AppSectionHeader(title: 'اشتراكات متأخّرة'),
                  ref
                      .watch(overdueHouseholdsProvider)
                      .when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => _Retry(
                          message: 'تعذّر تحميل الاشتراكات',
                          onRetry: () =>
                              ref.invalidate(overdueHouseholdsProvider),
                        ),
                        data: (List<HouseholdSummary> households) => Column(
                          children: <Widget>[
                            if (households.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                child: Text('مفيش اشتراكات متأخّرة'),
                              ),
                            for (final HouseholdSummary h in households)
                              AppListCard(
                                title: h.name,
                                subtitle:
                                    '${arabicNumber(h.monthlyAmount)} ج.م شهريًا',
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
                  const AppSectionHeader(title: 'يحتاج قرارك'),
                  _Queue(
                    state: ref.watch(pendingExcusesControllerProvider),
                    title: 'أعذار غياب',
                    route: Routes.supervisorExcuses,
                  ),
                  _Queue(
                    state: ref.watch(pendingMonthlyEvalsProvider),
                    title: 'تقييمات شهرية',
                    route: Routes.supervisorMonthlyEval,
                  ),
                  _Queue(
                    state: ref.watch(pendingDevelopmentProvider),
                    title: 'تطوّر المعلّمين',
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
                    title: 'طلاب محتاجين متابعة',
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
    loading: () => const LinearProgressIndicator(),
    error: (_, _) => Text('تعذّر تحميل $title'),
    data: (List<T> rows) => rows.isEmpty && !alwaysShow
        ? const SizedBox.shrink()
        : AppListCard(
            title:
                '$title (${arabicNumber(rows.length)}${rows.length >= 50 ? '+' : ''})',
            onTap: () => context.push(route),
          ),
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
      child: const Text('إعادة المحاولة'),
    ),
  );
}

/// "تسجيل دفعة" من الهوم: اختيار الأسرة (بحث) ← شيت الدفعة.
Future<void> _recordPaymentFlow(BuildContext context, WidgetRef ref) async {
  final SubscriptionRepository repo = ref.read(subscriptionRepositoryProvider);
  final HouseholdSummary? household =
      await showAppServerSearchPicker<HouseholdSummary>(
        context: context,
        title: 'اختار الأسرة',
        searchLabel: 'بحث باسم الأسرة',
        search: (String q) => repo.fetchHouseholds(query: q),
        label: (HouseholdSummary h) => h.name,
      );
  if (household == null || !context.mounted) return;
  await showAppModalSheet<void>(
    context: context,
    title: 'تسجيل دفعة',
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
    final SyncStatus? status = ref.watch(syncStatusProvider).asData?.value;
    final int pending = status?.pending ?? 0;
    final bool failed = status?.hasFailures ?? false;
    final String label = pending > 0
        ? 'حالة المزامنة — ${arabicNumber(pending)} مستني الإرسال'
        : failed
        ? 'حالة المزامنة — فيه عمليات فشلت'
        : 'حالة المزامنة';
    return Semantics(
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
              ? 'حالة المزامنة (${arabicNumber(pending)} معلّق)'
              : 'حالة المزامنة',
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
    final AsyncValue<ChildCard> state = ref.watch(
      childCardProvider(child.studentPersonId),
    );
    // الاشتراك على مستوى الأسرة — نفس الحالة لكل طفل في نفس الحساب.
    final bool? subscribed = ref
        .watch(mySubscriptionActiveProvider)
        .asData
        ?.value;
    return AppListCard(
      title: child.fullName,
      leadingIcon: Icons.child_care,
      subtitle: state.when(
        loading: () => 'جاري تحميل التقدّم…',
        error: (_, _) => 'تعذّر تحميل التقدّم — افتح البطاقة لإعادة المحاولة',
        data: (ChildCard card) {
          final String? portion = card.currentPortion;
          final String portionLine = portion == null || portion.trim().isEmpty
              ? 'لسه مفيش ورد محدّد'
              : 'الورد الحالي: $portion';
          return '$portionLine\nحضور الشهر: ${arabicNumber(card.present + card.late)}/${arabicNumber(card.present + card.late + card.absent + card.excused)}';
        },
      ),
      trailing: subscribed == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppStatusBadge(
                  label: subscribed ? 'الاشتراك ساري' : 'الاشتراك متأخّر',
                  kind: subscribed
                      ? AppStatusKind.success
                      : AppStatusKind.warning,
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

/// كارت حلقة في الهوم — بيودّي لشاشة الحصة بس؛ فتح الحصة نفسه قرار المعلّم
/// من جوّه الشاشة (مش side effect للنقر هنا).
class _TeacherCircle extends ConsumerWidget {
  const _TeacherCircle({required this.circle});
  final Circle circle;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TodaySession> state = ref.watch(
      todaySessionControllerProvider(circle.id),
    );
    return AppListCard(
      title: circle.name,
      leadingIcon: Icons.menu_book,
      subtitle: state.when(
        loading: () => 'جاري تحميل الحصة…',
        error: (_, _) => 'تعذّر تحميل الحصة — افتح الحلقة لإعادة المحاولة',
        data: (TodaySession s) => s.isOpen
            ? 'الحصة مفتوحة — كمّل'
            : s.closedToday
            ? 'الحصة اتقفلت — ${arabicNumber(s.presentCount)} حضور، ${arabicNumber(s.tasmeeCount)} تسميع'
            : 'حصة النهارده لسه ما اتفتحتش',
      ),
      onTap: () => context.push<void>(Routes.session(circle.id, circle.name)),
    );
  }
}
