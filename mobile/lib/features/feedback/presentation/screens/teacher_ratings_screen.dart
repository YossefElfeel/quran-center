import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/teacher_rating_row.dart';
import '../controllers/feedback_controllers.dart';

/// تقييمات أولياء الأمور للمحفّظين — خاصة للمدير/المشرف (المعلّم مايشوفهاش).
class TeacherRatingsScreen extends ConsumerWidget {
  const TeacherRatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<TeacherRatingRow>> state = ref.watch(
      teacherRatingsProvider,
    );
    final List<String> roles =
        ref.watch(currentRolesProvider).asData?.value ?? const <String>[];
    final bool isAdmin =
        roles.contains('admin') || roles.contains('super_admin');
    return AppScaffold(
      title: l.fbkTeacherRatingsTitle,
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.fbkLoadRatingsError,
          onRetry: () => ref.invalidate(teacherRatingsProvider),
        ),
        data: (List<TeacherRatingRow> items) => items.isEmpty
            ? EmptyState(message: l.fbkNoRatings, icon: Icons.star_outline)
            : AppRefreshIndicator(
                onRefresh: () async => ref.invalidate(teacherRatingsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) =>
                      _RatingCard(rating: items[i], isAdmin: isAdmin),
                ),
              ),
      ),
    );
  }
}

class _RatingCard extends ConsumerWidget {
  const _RatingCard({required this.rating, required this.isAdmin});

  final TeacherRatingRow rating;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      child: Opacity(
        opacity: rating.hidden ? 0.5 : 1,
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      rating.teacherName,
                      style: AppTextStyles.titleMd.copyWith(
                        color: p.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${arabicNumber(rating.stars)} ⭐',
                    style: AppTextStyles.titleMd.copyWith(color: p.accent),
                  ),
                ],
              ),
              if (rating.comment != null && rating.comment!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    rating.comment!,
                    style: AppTextStyles.bodyMd.copyWith(color: p.textPrimary),
                  ),
                ),
              if (isAdmin)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AppButton(
                    label: rating.hidden ? l.fbkShow : l.fbkHide,
                    icon: rating.hidden
                        ? Icons.visibility
                        : Icons.visibility_off,
                    onPressed: () => ref
                        .read(teacherRatingsProvider.notifier)
                        .setHidden(rating.id, !rating.hidden),
                    variant: AppButtonVariant.text,
                    expanded: false,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
