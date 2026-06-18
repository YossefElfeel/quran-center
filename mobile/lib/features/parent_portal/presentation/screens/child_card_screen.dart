import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../domain/child_card.dart';
import '../controllers/child_card_controller.dart';
import '../widgets/child_comments_section.dart';
import '../widgets/child_consent_section.dart';
import '../widgets/child_journey_section.dart';
import '../widgets/child_monthly_plan_section.dart';

/// كارت متابعة الطفل: الحلقة + آخر تسميع + ملخّص الحضور.
class ChildCardScreen extends ConsumerWidget {
  const ChildCardScreen({
    required this.studentPersonId,
    required this.childName,
    super.key,
  });

  final String studentPersonId;
  final String childName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ChildCard> state = ref.watch(
      childCardProvider(studentPersonId),
    );
    return AppScaffold(
      title: childName,
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الكارت',
          onRetry: () => ref.invalidate(childCardProvider(studentPersonId)),
        ),
        data: (ChildCard card) {
          final LatestTasmee? lt = card.latestTasmee;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              _InfoCard(
                icon: Icons.groups,
                title: 'الحلقة',
                value: card.circleName ?? 'مش في حلقة دلوقتي',
              ),
              if (lt != null)
                _InfoCard(
                  icon: Icons.record_voice_over,
                  title: 'آخر تسميع',
                  value:
                      '${lt.portionName} — ${arabicNumber(lt.score)}/١٠ '
                      '(${lt.passed ? 'ناجح' : 'محتاج إعادة'})',
                  valueColor: lt.passed ? AppColors.success : AppColors.error,
                ),
              _AttendanceCard(card: card),
              ChildMonthlyPlanSection(studentPersonId: studentPersonId),
              ChildJourneySection(studentPersonId: studentPersonId),
              if (card.isGirl)
                ChildConsentSection(studentPersonId: studentPersonId),
              ChildCommentsSection(studentPersonId: studentPersonId),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.card});

  final ChildCard card;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'الحضور',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                _Pill(
                  label: 'حاضر',
                  count: card.present,
                  color: AppColors.success,
                ),
                _Pill(
                  label: 'غايب',
                  count: card.absent,
                  color: AppColors.error,
                ),
                _Pill(
                  label: 'بعذر',
                  count: card.excused,
                  color: AppColors.accent,
                ),
                _Pill(
                  label: 'متأخّر',
                  count: card.late,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        '$label: ${arabicNumber(count)}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
