import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_date.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/recognition_repository.dart';
import '../../domain/top_student_row.dart';

/// لوحة الشرف — متفوّقو الشهر لكل حلقة (علني جوّا التطبيق).
class HonorBoardScreen extends ConsumerWidget {
  const HonorBoardScreen({super.key});

  /// تفصيل احتفائي: سبب التميّز كامل + الحلقة + الشهر.
  void _openDetail(BuildContext context, TopStudentRow t) {
    showAppModalSheet<void>(
      context: context,
      builder: (BuildContext context) {
        final AppL10n l = AppL10n.of(context);
        final AppPalette p = context.palette;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  AppAvatar(name: t.studentName, radius: 36),
                  const SizedBox(height: AppSpacing.sm),
                  Icon(Icons.emoji_events, color: p.accent, size: 32),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t.studentName,
                    style: AppTextStyles.titleLg.copyWith(color: p.textPrimary),
                  ),
                  Text(
                    '${t.circleName} · ${arabicMonthLabel(t.month)}',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l.recReasonLabel,
              style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              (t.reason == null || t.reason!.isEmpty)
                  ? l.recNoReason
                  : t.reason!,
              style: AppTextStyles.bodyLg.copyWith(color: p.textPrimary),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<TopStudentRow>> state = ref.watch(honorBoardProvider);
    return AppScaffold(
      title: l.recHonorBoardTitle,
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.recHonorBoardLoadError,
          onRetry: () => ref.invalidate(honorBoardProvider),
        ),
        data: (List<TopStudentRow> items) => items.isEmpty
            ? EmptyState(
                message: l.recNoTopStudents,
                icon: Icons.emoji_events_outlined,
              )
            : AppRefreshIndicator(
                onRefresh: () async => ref.invalidate(honorBoardProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) {
                    final TopStudentRow t = items[i];
                    return AppListCard(
                      leading: AppAvatar(name: t.studentName),
                      trailing: Icon(
                        Icons.emoji_events,
                        color: context.palette.accent,
                        size: 28,
                      ),
                      title: t.studentName,
                      subtitle:
                          '${t.circleName} — '
                          '${arabicNumber(t.month.month)}/'
                          '${arabicNumber(t.month.year)}',
                      onTap: () => _openDetail(context, t),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
