import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../supervisor_eval/domain/circle_pass_rate.dart';
import '../../../supervisor_eval/presentation/controllers/circle_pass_rates_controller.dart';
import '../controllers/teacher_controllers.dart';

/// تفاصيل نسبة نجاح المعلّم — الإجمالي + تفصيل لكل حلقة (مصدر النسبة).
class TeacherPassRateScreen extends ConsumerWidget {
  const TeacherPassRateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<CirclePassRate>> circles = ref.watch(
      circlePassRatesProvider,
    );
    return AppScaffold(
      title: l.tchPassRateTitle,
      body: AppRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myPassRateProvider);
          ref.invalidate(circlePassRatesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: <Widget>[
            const _OverallCard(),
            AppSectionHeader(title: l.tchPassRateByCircle),
            circles.when(
              loading: () => const AppListSkeleton(itemCount: 3),
              error: (Object e, StackTrace _) => AppErrorView(
                message: l.tchPassRateLoadError,
                onRetry: () => ref.invalidate(circlePassRatesProvider),
              ),
              data: (List<CirclePassRate> list) => list.isEmpty
                  ? EmptyState(
                      message: l.tchNoCirclesYet,
                      icon: Icons.groups_outlined,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (final CirclePassRate c in list)
                          _CircleRateTile(circle: c),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// كارت الإجمالي: نسبة كبيرة + شرح طريقة الحساب.
class _OverallCard extends ConsumerWidget {
  const _OverallCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final AsyncValue<double> rate = ref.watch(myPassRateProvider);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: AppOpacity.badgeTint),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.insights, color: p.primary, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l.tchPassRateOverall,
                    style: AppTextStyles.titleMd.copyWith(color: p.textPrimary),
                  ),
                ),
                rate.maybeWhen(
                  orElse: () => const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  data: (double r) => Text(
                    l.tchPassRatePercent(arabicNumber((r * 100).round())),
                    style: AppTextStyles.headlineMd.copyWith(
                      color: p.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.tchPassRateExplain,
              style: AppTextStyles.bodyMd.copyWith(color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// صف حلقة: الاسم + عدّى كام من كام + النسبة ملوّنة حسب الحالة.
class _CircleRateTile extends StatelessWidget {
  const _CircleRateTile({required this.circle});

  final CirclePassRate circle;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final bool noPortion = circle.passRate == null;
    final Color color = noPortion
        ? p.textSecondary
        : (circle.needsAttention ? p.error : p.success);
    return AppListCard(
      leadingIcon: noPortion
          ? Icons.remove_circle_outline
          : (circle.needsAttention ? Icons.trending_down : Icons.trending_up),
      iconColor: color,
      title: circle.circleName,
      subtitle: noPortion
          ? l.tchCircleNoCurrentPortion
          : l.supCirclePassedOf(
              arabicNumber(circle.passedCount),
              arabicNumber(circle.activeAtOpen),
            ),
      trailing: noPortion
          ? null
          : Text(
              l.supPercent(arabicNumber(circle.percent)),
              style: AppTextStyles.titleMd.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
