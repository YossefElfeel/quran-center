import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/presentation/domain_labels.dart';
import '../../../../shared/theme/app_icons.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/center_contact_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../admin_setup/domain/circle.dart';
import '../controllers/my_circles_controller.dart';

/// حلقات المعلّم — يختار حلقة يفتح حصتها.
class MyCirclesScreen extends ConsumerWidget {
  const MyCirclesScreen({this.appBarBottom, super.key});

  /// شريط اختياري تحت العنوان (سويتش الدورين في التبويب الأساسي).
  final PreferredSizeWidget? appBarBottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<Circle>> state = ref.watch(myCirclesProvider);
    return AppScaffold(
      title: l.sesMyCirclesTitle,
      bottom: appBarBottom,
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.sesMyCirclesLoadError,
          onRetry: () => ref.invalidate(myCirclesProvider),
        ),
        data: (List<Circle> items) => items.isEmpty
            ? EmptyState(
                message: l.sesNoCircles,
                action: const CenterContactButton(),
                icon: Icons.groups_outlined,
              )
            : AppRefreshIndicator(
                onRefresh: () async => ref.invalidate(myCirclesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) =>
                      MyCircleCard(circle: items[i]),
                ),
              ),
      ),
    );
  }
}

/// كارت حلقة للمعلّم: الاسم + "الحالة · عدد الطلبة"، والنقر يفتح الحصة،
/// وتحته زرّين واضحين بنص (الخطة الشهرية / التقييم الشهري) بدل أيقونات بس.
class MyCircleCard extends StatelessWidget {
  const MyCircleCard({required this.circle, super.key});

  final Circle circle;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final Circle c = circle;
    final int? count = c.activeStudentCount;
    final String status = c.status.label(l);
    final String subtitle = count == null
        ? status
        : l.fyCircleRowSubtitle(
            status,
            l.enrCircleStudentCount(count, arabicNumber(count)),
          );
    final ButtonStyle chipStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(48, 40),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
      visualDensity: VisualDensity.compact,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm + 2,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        onTap: () => context.push(Routes.session(c.id, c.name)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MergeSemantics(
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.primary.withValues(alpha: AppOpacity.badgeTint),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.groups, color: p.primary, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          c.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMd.copyWith(
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(AppIcons.drillIn, color: p.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                OutlinedButton.icon(
                  style: chipStyle,
                  onPressed: () =>
                      context.push(Routes.monthlyPlan(c.id, c.name)),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(l.fyMonthlyPlanChip),
                ),
                OutlinedButton.icon(
                  style: chipStyle,
                  onPressed: () =>
                      context.push(Routes.monthlyEval(c.id, c.name)),
                  icon: const Icon(Icons.fact_check, size: 18),
                  label: Text(l.fyMonthlyEvalChip),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
