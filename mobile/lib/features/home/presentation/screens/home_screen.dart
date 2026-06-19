import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';

String _roleLabel(AppL10n l, String role) {
  switch (role) {
    case 'super_admin':
      return l.roleSuperAdmin;
    case 'admin':
      return l.roleAdmin;
    case 'supervisor':
      return l.roleSupervisor;
    case 'teacher':
      return l.roleTeacher;
    case 'parent':
      return l.roleParent;
    default:
      return role;
  }
}

/// الرئيسية بعد الدخول — بتعرض أدوار المستخدم (بتثبت إن RLS شغّال) + خروج.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<String>> rolesAsync = ref.watch(currentRolesProvider);
    return AppScaffold(
      title: l.appTitle,
      actions: <Widget>[
        const _NotificationBell(),
        IconButton(
          tooltip: l.logout,
          icon: const Icon(Icons.logout),
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
      body: rolesAsync.when(
        loading: () => AppLoader(message: l.loading),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.genericError,
          onRetry: () => ref.invalidate(currentRolesProvider),
        ),
        data: (List<String> roles) => _HomeBody(roles: roles),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.roles});

  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return SingleChildScrollView(
      child: Padding(
        key: const Key('home_body'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.menu_book, size: 64, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.welcome,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (roles.isEmpty)
              Text(
                l.noRoleYet,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: roles.map((String r) => _RoleChip(role: r)).toList(),
              ),
            if (roles.contains('admin') ||
                roles.contains('super_admin')) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: l.navCurriculaCircles,
                icon: Icons.account_tree,
                onPressed: () => context.go(Routes.adminCurricula),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.navWaitingList,
                icon: Icons.how_to_reg,
                onPressed: () => context.go(Routes.adminWaiting),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.navSubscriptions,
                icon: Icons.payments,
                onPressed: () => context.go(Routes.adminSubscriptions),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.navGuardianLinks,
                icon: Icons.link,
                onPressed: () => context.go(Routes.adminGuardians),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.navInviteUser,
                icon: Icons.person_add,
                onPressed: () => context.go(Routes.adminInviteUser),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.navComplaintsInbox,
                icon: Icons.inbox,
                onPressed: () => context.go(Routes.complaintsInbox),
              ),
            ],
            if (roles.contains('teacher')) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: l.navMyCircles,
                icon: Icons.menu_book,
                onPressed: () => context.go(Routes.teacherCircles),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.navMyProfileDev,
                icon: Icons.trending_up,
                onPressed: () => context.go(Routes.teacherDevelopment),
              ),
            ],
            if (roles.contains('parent')) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: l.navMyChildren,
                icon: Icons.child_care,
                onPressed: () => context.go(Routes.parentChildren),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.navMyComplaints,
                icon: Icons.support_agent,
                onPressed: () => context.go(Routes.complaintsMine),
              ),
            ],
            if (roles.contains('supervisor') ||
                roles.contains('admin') ||
                roles.contains('super_admin')) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: l.navEvalCircles,
                icon: Icons.fact_check,
                onPressed: () => context.go(Routes.supervisorEval),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.navExcuses,
                icon: Icons.event_busy,
                onPressed: () => context.go(Routes.supervisorExcuses),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.navAttention,
                icon: Icons.warning_amber,
                onPressed: () => context.go(Routes.supervisorAttention),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.navTeacherDev,
                icon: Icons.school,
                onPressed: () => context.go(Routes.supervisorDevApproval),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.navMonthlyEvalApproval,
                icon: Icons.assignment_turned_in,
                onPressed: () => context.go(Routes.supervisorMonthlyEval),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.navIssueCertificates,
                icon: Icons.workspace_premium,
                onPressed: () => context.go(Routes.issueCertificate),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.navTeacherRatings,
                icon: Icons.star_half,
                onPressed: () => context.go(Routes.teacherRatings),
              ),
            ],
            if (roles.contains('admin') ||
                roles.contains('super_admin') ||
                roles.contains('supervisor') ||
                roles.contains('teacher')) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: l.navCompetitions,
                icon: Icons.emoji_events,
                onPressed: () => context.go(Routes.competitions),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l.navHonorBoard,
              icon: Icons.emoji_events,
              onPressed: () => context.go(Routes.honorBoard),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l.navCourses,
              icon: Icons.ondemand_video,
              onPressed: () => context.go(Routes.courses),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_roleLabel(AppL10n.of(context), role)),
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = ref.watch(unreadCountProvider).asData?.value ?? 0;
    final Widget bell = IconButton(
      tooltip: AppL10n.of(context).notificationsTooltip,
      icon: const Icon(Icons.notifications),
      onPressed: () => context.go(Routes.notifications),
    );
    return count == 0 ? bell : Badge.count(count: count, child: bell);
  }
}
