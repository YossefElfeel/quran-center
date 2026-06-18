import 'package:flutter/material.dart';

import '../../../../shared/theme/tokens.dart';
import '../../domain/portion.dart';

/// شريط المراجعة المطلوبة النهارده (من خطة الحصة السابقة) — تذكير للمعلّم.
/// التسميع على المراجعة بيتعمل من شيت التسميع (مفتاح حفظ/مراجعة).
class RequiredRevisionBanner extends StatelessWidget {
  const RequiredRevisionBanner({required this.revision, super.key});

  final Portion revision;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: AppColors.accent.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            const Icon(Icons.replay, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'المراجعة المطلوبة النهارده',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    revision.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
