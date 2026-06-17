import 'package:flutter/material.dart';

import '../../../../shared/theme/tokens.dart';
import '../../domain/curriculum.dart';

/// بلاطة منهج في القائمة.
class CurriculumTile extends StatelessWidget {
  const CurriculumTile({
    required this.curriculum,
    required this.onTap,
    super.key,
  });

  final Curriculum curriculum;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListTile(
        leading: const Icon(Icons.menu_book, color: AppColors.primary),
        title: Text(curriculum.name),
        subtitle: Text(curriculum.type.labelAr),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
