import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../admin_setup/domain/circle.dart';
import '../controllers/my_circles_controller.dart';

/// حلقات المعلّم — يختار حلقة يفتح حصتها.
class MyCirclesScreen extends ConsumerWidget {
  const MyCirclesScreen({super.key});

  AppStatusKind _statusKind(CircleStatus s) {
    switch (s) {
      case CircleStatus.active:
        return AppStatusKind.success;
      case CircleStatus.forming:
        return AppStatusKind.warning;
      case CircleStatus.graduated:
        return AppStatusKind.neutral;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<Circle>> state = ref.watch(myCirclesProvider);
    return AppScaffold(
      title: l.sesMyCirclesTitle,
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.sesMyCirclesLoadError,
          onRetry: () => ref.invalidate(myCirclesProvider),
        ),
        data: (List<Circle> items) => items.isEmpty
            ? EmptyState(message: l.sesNoCircles, icon: Icons.groups_outlined)
            : AppRefreshIndicator(
                onRefresh: () async => ref.invalidate(myCirclesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) {
                    final Circle c = items[i];
                    return AppListCard(
                      title: c.name,
                      subtitle: c.status.labelAr,
                      leadingIcon: Icons.groups,
                      onTap: () => context.push(Routes.session(c.id, c.name)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _StatusDot(kind: _statusKind(c.status)),
                          IconButton(
                            tooltip: l.sesMonthlyPlan,
                            icon: const Icon(Icons.calendar_month),
                            onPressed: () =>
                                context.push(Routes.monthlyPlan(c.id, c.name)),
                          ),
                          IconButton(
                            tooltip: l.sesMonthlyEval,
                            icon: const Icon(Icons.fact_check),
                            onPressed: () =>
                                context.push(Routes.monthlyEval(c.id, c.name)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

/// نقطة حالة صغيرة ملوّنة.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.kind});

  final AppStatusKind kind;

  Color _color(AppPalette p) {
    switch (kind) {
      case AppStatusKind.success:
        return p.success;
      case AppStatusKind.warning:
        return p.warning;
      case AppStatusKind.error:
        return p.error;
      case AppStatusKind.info:
        return p.info;
      case AppStatusKind.primary:
        return p.primary;
      case AppStatusKind.neutral:
        return p.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _color(context.palette),
        shape: BoxShape.circle,
      ),
    );
  }
}
