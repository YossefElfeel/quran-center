import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../domain/circle_pass_rate.dart';
import '../../domain/struggling_student.dart';
import '../controllers/circle_pass_rates_controller.dart';
import '../controllers/struggling_controller.dart';

/// "محتاج انتباه" — حلقات نسبتها أقل من النص + طلبة متعثّرين.
class AttentionScreen extends ConsumerWidget {
  const AttentionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    return AppScaffold(
      title: l.navAttention,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: <Widget>[
          AppSectionHeader(title: l.supAttentionCirclesSection),
          const _CirclesSection(),
          const SizedBox(height: AppSpacing.sm),
          AppSectionHeader(title: l.supAttentionStrugglingSection),
          const _StrugglingSection(),
        ],
      ),
    );
  }
}

class _CirclesSection extends ConsumerWidget {
  const _CirclesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<CirclePassRate>> state = ref.watch(
      circlePassRatesProvider,
    );
    return state.when(
      loading: () =>
          const SizedBox(height: 240, child: AppListSkeleton(itemCount: 3)),
      error: (Object e, StackTrace _) => AppErrorView(
        message: l.supCirclesLoadError,
        onRetry: () => ref.invalidate(circlePassRatesProvider),
      ),
      data: (List<CirclePassRate> list) {
        final List<CirclePassRate> attention = list
            .where((CirclePassRate c) => c.needsAttention)
            .toList();
        if (attention.isEmpty) {
          return _EmptyNote(l.supAllCirclesAboveHalf);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: attention
              .map((CirclePassRate c) => _CircleTile(circle: c))
              .toList(),
        );
      },
    );
  }
}

class _CircleTile extends StatelessWidget {
  const _CircleTile({required this.circle});

  final CirclePassRate circle;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return AppListCard(
      leadingIcon: Icons.trending_down,
      iconColor: p.error,
      title: circle.circleName,
      subtitle: l.supCirclePassedOf(
        arabicNumber(circle.passedCount),
        arabicNumber(circle.activeAtOpen),
      ),
      trailing: Text(
        l.supPercent(arabicNumber(circle.percent)),
        style: AppTextStyles.titleMd.copyWith(
          color: p.error,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StrugglingSection extends ConsumerWidget {
  const _StrugglingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<StrugglingStudent>> state = ref.watch(
      strugglingStudentsProvider,
    );
    return state.when(
      loading: () =>
          const SizedBox(height: 240, child: AppListSkeleton(itemCount: 3)),
      error: (Object e, StackTrace _) => AppErrorView(
        message: l.supListLoadError,
        onRetry: () => ref.invalidate(strugglingStudentsProvider),
      ),
      data: (List<StrugglingStudent> items) {
        if (items.isEmpty) {
          return _EmptyNote(l.supNoStrugglingStudents);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: items
              .map((StrugglingStudent s) => _StrugglingTile(student: s))
              .toList(),
        );
      },
    );
  }
}

class _StrugglingTile extends StatelessWidget {
  const _StrugglingTile({required this.student});

  final StrugglingStudent student;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return AppListCard(
      leadingIcon: Icons.warning_amber,
      iconColor: p.error,
      title: student.studentName,
      subtitle: l.supStudentDebt(
        student.portionName,
        arabicNumber(student.attempts),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        text,
        style: AppTextStyles.bodyMd.copyWith(color: p.textSecondary),
      ),
    );
  }
}
