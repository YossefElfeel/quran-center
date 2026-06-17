import 'package:flutter/material.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../domain/level.dart';

/// بلاطة مستوى (بترقم الترتيب) قابلة للضغط للدخول على حلقاته.
class LevelTile extends StatelessWidget {
  const LevelTile({required this.level, required this.onTap, super.key});

  final Level level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: Text(arabicNumber(level.ord)),
        ),
        title: Text(level.name),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
