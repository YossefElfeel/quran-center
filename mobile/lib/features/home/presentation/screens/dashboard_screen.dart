import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/motion.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_stat_pill.dart';
import '../../../monthly/presentation/controllers/monthly_eval_controllers.dart';
import '../../../more/favorites_provider.dart';
import '../../../more/feature_catalog.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../parent_portal/presentation/controllers/my_children_controller.dart';
import '../../../session/presentation/controllers/my_circles_controller.dart';
import '../../../supervisor_eval/presentation/controllers/struggling_controller.dart';

const List<String> _supervisorRoles = <String>[
  'supervisor',
  'admin',
  'super_admin',
];

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

/// الداشبورد — يستبدل قائمة الأزرار القديمة: hero + إجراءات سريعة + نظرة عامة.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<String?> personIdAsync = ref.watch(
      currentPersonIdProvider,
    );
    final AsyncValue<List<String>> rolesAsync = ref.watch(currentRolesProvider);

    return Scaffold(
      body: personIdAsync.when(
        loading: () => AppLoader(message: l.loading),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.genericError,
          onRetry: () => ref.invalidate(currentPersonIdProvider),
        ),
        data: (String? personId) {
          if (personId == null) {
            return _SuspendedBody(
              onSignOut: () => ref.read(authRepositoryProvider).signOut(),
            );
          }
          return rolesAsync.when(
            loading: () => AppLoader(message: l.loading),
            error: (Object e, StackTrace _) => AppErrorView(
              message: l.genericError,
              onRetry: () => ref.invalidate(currentRolesProvider),
            ),
            data: (List<String> roles) => _DashboardBody(roles: roles),
          );
        },
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.roles});

  final List<String> roles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool noMotion = reduceMotion(context);

    Widget anim(Widget child, int i) => noMotion
        ? child
        : child
              .animate()
              .fadeIn(duration: AppDurations.base, delay: (i * 70).ms)
              .slideY(begin: 0.08, curve: AppCurves.emphasized);

    return AppRefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(currentRolesProvider)
          ..invalidate(unreadCountProvider)
          ..invalidate(myCirclesProvider)
          ..invalidate(myChildrenProvider)
          ..invalidate(strugglingStudentsProvider)
          ..invalidate(pendingMonthlyEvalsProvider);
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _HeroHeader(roles: roles),
          anim(_QuickActions(roles: roles), 1),
          anim(_SummarySection(roles: roles), 2),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.roles});

  final List<String> roles;

  String _greeting(AppL10n l) {
    final int h = DateTime.now().hour;
    if (h < 12) return l.greetingMorning;
    if (h < 18) return l.greetingAfternoon;
    return l.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: p.heroGradient,
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.xl),
        ),
        boxShadow: AppElevation.shadowMd(p.shadowColor),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _greeting(l),
                          style: AppTextStyles.headlineMd.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.welcome,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _HeroBell(),
                  const _HeroSettings(),
                ],
              ),
              if (roles.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    for (final String r in roles)
                      _HeroRoleChip(label: _roleLabel(l, r)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroRoleChip extends StatelessWidget {
  const _HeroRoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroBell extends ConsumerWidget {
  const _HeroBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = ref.watch(unreadCountProvider).asData?.value ?? 0;
    final Widget bell = IconButton(
      tooltip: AppL10n.of(context).notificationsTooltip,
      color: Colors.white,
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () => context.go(Routes.notifications),
    );
    return count == 0 ? bell : Badge.count(count: count, child: bell);
  }
}

class _HeroSettings extends StatelessWidget {
  const _HeroSettings();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppL10n.of(context).settingsTitle,
      color: Colors.white,
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => context.push(Routes.settings),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.roles});

  final List<String> roles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final List<String> favs = ref.watch(favoritesProvider);
    final List<FeatureItem> visible = featuresFor(roles);

    // المفضّلة أولاً، ثم باقي الميزات — بحد أقصى ٦ مربّعات.
    final List<FeatureItem> ordered = <FeatureItem>[
      for (final String route in favs)
        ...visible.where((FeatureItem f) => f.route == route),
      ...visible.where((FeatureItem f) => !favs.contains(f.route)),
    ].take(6).toList();

    if (ordered.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l.quickActions, style: AppTextStyles.titleMd),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 190,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.5,
            ),
            itemCount: ordered.length,
            itemBuilder: (BuildContext context, int i) =>
                _QuickTile(item: ordered[i]),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.item});

  final FeatureItem item;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return AppCard(
      onTap: () => context.push(item.route),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: AppOpacity.badgeTint),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(item.icon, color: p.primary, size: 22),
          ),
          Text(
            item.label(AppL10n.of(context)),
            style: AppTextStyles.labelLg.copyWith(color: p.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.roles});

  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final bool isTeacher = roles.contains('teacher');
    final bool isParent = roles.contains('parent');
    final bool isSupervisor = roles.any(_supervisorRoles.contains);

    final List<Widget> tiles = <Widget>[
      const _UnreadStat(),
      if (isTeacher) const _MyCirclesStat(),
      if (isParent) const _MyChildrenStat(),
      if (isSupervisor) ...<Widget>[
        const _AttentionStat(),
        const _PendingApprovalsStat(),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l.overview, style: AppTextStyles.titleMd),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisExtent: 80,
            ),
            itemCount: tiles.length,
            itemBuilder: (BuildContext context, int i) => tiles[i],
          ),
        ],
      ),
    );
  }
}

/// أداة مساعدة: `AsyncValue<int>` ← AppStatPill بمؤشّر تحميل بسيط.
Widget _statTile(
  BuildContext context,
  AsyncValue<int> value, {
  required String label,
  required IconData icon,
  Color? color,
  VoidCallback? onTap,
}) {
  return value.when(
    data: (int v) => AppStatPill(
      value: v,
      label: label,
      icon: icon,
      color: color,
      onTap: onTap,
    ),
    loading: () =>
        AppStatPill(value: 0, label: label, icon: icon, color: color),
    error: (Object e, StackTrace _) => AppStatPill(
      value: 0,
      label: label,
      icon: icon,
      color: color,
      onTap: onTap,
    ),
  );
}

class _UnreadStat extends ConsumerWidget {
  const _UnreadStat();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    return _statTile(
      context,
      ref.watch(unreadCountProvider),
      label: l.statUnread,
      icon: Icons.notifications_outlined,
      color: context.palette.info,
      onTap: () => context.go(Routes.notifications),
    );
  }
}

class _MyCirclesStat extends ConsumerWidget {
  const _MyCirclesStat();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    return _statTile(
      context,
      ref.watch(myCirclesProvider).whenData((List<dynamic> v) => v.length),
      label: l.statMyCircles,
      icon: Icons.menu_book_outlined,
      onTap: () => context.go(Routes.primaryTab),
    );
  }
}

class _MyChildrenStat extends ConsumerWidget {
  const _MyChildrenStat();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    return _statTile(
      context,
      ref.watch(myChildrenProvider).whenData((List<dynamic> v) => v.length),
      label: l.statMyChildren,
      icon: Icons.child_care_outlined,
      onTap: () => context.go(Routes.primaryTab),
    );
  }
}

class _AttentionStat extends ConsumerWidget {
  const _AttentionStat();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    return _statTile(
      context,
      ref
          .watch(strugglingStudentsProvider)
          .whenData((List<dynamic> v) => v.length),
      label: l.statNeedsAttention,
      icon: Icons.warning_amber,
      color: context.palette.warning,
      onTap: () => context.push(Routes.supervisorAttention),
    );
  }
}

class _PendingApprovalsStat extends ConsumerWidget {
  const _PendingApprovalsStat();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    return _statTile(
      context,
      ref
          .watch(pendingMonthlyEvalsProvider)
          .whenData((List<dynamic> v) => v.length),
      label: l.navMonthlyEvalApproval,
      icon: Icons.assignment_turned_in,
      onTap: () => context.push(Routes.supervisorMonthlyEval),
    );
  }
}

class _SuspendedBody extends StatelessWidget {
  const _SuspendedBody({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.lock_outline, size: 64, color: p.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.accountSuspendedTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLg.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.accountSuspendedMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l.logout,
              icon: Icons.logout,
              expanded: false,
              onPressed: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}
