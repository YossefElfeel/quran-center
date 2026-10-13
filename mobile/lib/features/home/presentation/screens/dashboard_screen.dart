import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/shell/sync_status_sheet.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/settings/settings_repository.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/arabic_date.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_snackbar.dart';
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
import '../../../subscription/domain/household_summary.dart';
import '../../../subscription/domain/subscription_status.dart';
import '../../../subscription/presentation/controllers/households_controller.dart';
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
              ref.invalidate(householdsControllerProvider);
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
                  TextButton.icon(
                    onPressed: () => SyncStatusSheet.show(context),
                    icon: const Icon(Icons.sync),
                    label: const Text('حالة المزامنة'),
                  ),
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
                    onPressed: () => context.push(Routes.adminSubscriptions),
                  ),
                  _Queue(
                    state: ref.watch(waitingListControllerProvider),
                    title: 'قائمة الانتظار',
                    route: Routes.adminWaiting,
                    alwaysShow: true,
                  ),
                  const AppSectionHeader(title: 'اشتراكات متأخّرة'),
                  ref
                      .watch(householdsControllerProvider)
                      .when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => _Retry(
                          message: 'تعذّر تحميل الاشتراكات',
                          onRetry: () =>
                              ref.invalidate(householdsControllerProvider),
                        ),
                        data: (List<HouseholdSummary> households) => Column(
                          children: <Widget>[
                            for (final HouseholdSummary h in households.where(
                              (HouseholdSummary h) =>
                                  h.status == SubscriptionStatus.overdue,
                            ))
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
                if (roles.any(
                  (String r) => <String>[
                    'teacher',
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

class _HomeChild extends ConsumerWidget {
  const _HomeChild({required this.child});
  final ChildSummary child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ChildCard> state = ref.watch(
      childCardProvider(child.studentPersonId),
    );
    return AppListCard(
      title: child.fullName,
      leadingIcon: Icons.child_care,
      subtitle: state.when(
        loading: () => 'جاري تحميل التقدّم…',
        error: (_, _) => 'تعذّر تحميل التقدّم — افتح البطاقة لإعادة المحاولة',
        data: (ChildCard card) {
          final LatestTasmee? last = card.latestTasmee;
          return '${last == null ? 'لسه مفيش تسميع' : 'آخر تسميع: ${arabicNumber(last.score)}/١٠ — ${last.portionName}'}\nحضور الشهر: ${arabicNumber(card.present + card.late)}/${arabicNumber(card.present + card.late + card.absent + card.excused)}';
        },
      ),
      onTap: () => context.push(
        Routes.parentChild(child.studentPersonId, child.fullName),
      ),
    );
  }
}

class _TeacherCircle extends ConsumerStatefulWidget {
  const _TeacherCircle({required this.circle});
  final Circle circle;
  @override
  ConsumerState<_TeacherCircle> createState() => _TeacherCircleState();
}

class _TeacherCircleState extends ConsumerState<_TeacherCircle> {
  bool _busy = false;
  Circle get circle => widget.circle;
  @override
  Widget build(BuildContext context) {
    final AsyncValue<TodaySession> state = ref.watch(
      todaySessionControllerProvider(circle.id),
    );
    return AppListCard(
      title: circle.name,
      leadingIcon: Icons.menu_book,
      subtitle: _busy
          ? 'جاري فتح الحصة…'
          : state.when(
              loading: () => 'جاري تحميل الحصة…',
              error: (_, _) =>
                  'تعذّر تحميل الحصة — افتح الحلقة لإعادة المحاولة',
              data: (TodaySession s) => s.isOpen
                  ? 'كمّل الحصة'
                  : s.closedToday
                  ? 'الحصة اتقفلت — ${arabicNumber(s.presentCount)} حضور، ${arabicNumber(s.tasmeeCount)} تسميع'
                  : 'افتح حصة النهارده',
            ),
      onTap: _busy
          ? null
          : () async {
              setState(() => _busy = true);
              try {
                final current = state.asData?.value;
                if (current != null &&
                    !current.isOpen &&
                    !current.closedToday &&
                    current.roster.isNotEmpty) {
                  await ref
                      .read(todaySessionControllerProvider(circle.id).notifier)
                      .openSession();
                }
                if (context.mounted) {
                  await context.push<void>(
                    Routes.session(circle.id, circle.name),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  AppSnackbar.error(
                    context,
                    'تعذّر فتح الحصة — راجع الاتصال وجرّب تاني',
                  );
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
    );
  }
}
