import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
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
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.fbkLoadRatingsError,
          onRetry: () => ref.invalidate(teacherRatingsProvider),
        ),
        data: (List<TeacherRatingRow> items) => items.isEmpty
            ? EmptyState(message: l.fbkNoRatings, icon: Icons.star_outline)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) =>
                    _RatingCard(rating: items[i], isAdmin: isAdmin),
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
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      child: Opacity(
        opacity: rating.hidden ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      rating.teacherName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${arabicNumber(rating.stars)} ⭐',
                    style: const TextStyle(color: AppColors.accent),
                  ),
                ],
              ),
              if (rating.comment != null && rating.comment!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(rating.comment!),
                ),
              if (isAdmin)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    icon: Icon(
                      rating.hidden ? Icons.visibility : Icons.visibility_off,
                    ),
                    label: Text(rating.hidden ? l.fbkShow : l.fbkHide),
                    onPressed: () => ref
                        .read(teacherRatingsProvider.notifier)
                        .setHidden(rating.id, !rating.hidden),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
