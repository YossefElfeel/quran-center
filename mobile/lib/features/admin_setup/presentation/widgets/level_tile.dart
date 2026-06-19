import 'package:flutter/material.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../domain/level.dart';

/// بلاطة مستوى (بترقم الترتيب) قابلة للضغط للدخول على حلقاته.
class LevelTile extends StatelessWidget {
  const LevelTile({required this.level, required this.onTap, super.key});

  final Level level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppListCard(
      title: level.name,
      leading: CircleAvatar(
        backgroundColor: context.palette.primary,
        foregroundColor: context.palette.onPrimary,
        child: Text(arabicNumber(level.ord)),
      ),
      onTap: onTap,
    );
  }
}
