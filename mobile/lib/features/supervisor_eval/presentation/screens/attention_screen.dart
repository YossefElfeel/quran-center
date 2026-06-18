import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
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
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          _SectionTitle(l.supAttentionCirclesSection),
          const _CirclesSection(),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(l.supAttentionStrugglingSection),
          const _StrugglingSection(),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: AppLoader(),
      ),
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListTile(
        leading: const Icon(Icons.trending_down, color: AppColors.error),
        title: Text(circle.circleName),
        subtitle: Text(
          l.supCirclePassedOf(
            arabicNumber(circle.passedCount),
            arabicNumber(circle.activeAtOpen),
          ),
        ),
        trailing: Text(
          l.supPercent(arabicNumber(circle.percent)),
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: AppLoader(),
      ),
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListTile(
        leading: const Icon(Icons.warning_amber, color: AppColors.error),
        title: Text(student.studentName),
        subtitle: Text(
          l.supStudentDebt(student.portionName, arabicNumber(student.attempts)),
        ),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
