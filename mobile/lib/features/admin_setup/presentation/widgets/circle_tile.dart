import 'package:flutter/material.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../domain/circle.dart';

/// بلاطة حلقة (المعلّم + السعة + الحالة).
class CircleTile extends StatelessWidget {
  const CircleTile({required this.circle, super.key});

  final Circle circle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListTile(
        leading: const Icon(Icons.groups, color: AppColors.primary),
        title: Text(circle.name),
        subtitle: Text(
          '${circle.teacherName ?? 'من غير معلّم'} • سعة '
          '${arabicNumber(circle.maxSize)}',
        ),
        trailing: _StatusBadge(status: circle.status),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CircleStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        status.labelAr,
        style: const TextStyle(fontSize: 12, color: AppColors.primaryDark),
      ),
    );
  }
}
