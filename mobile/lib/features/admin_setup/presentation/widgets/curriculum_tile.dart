import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_list_card.dart';
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
    return AppListCard(
      title: curriculum.name,
      subtitle: curriculum.type.labelAr,
      leadingIcon: Icons.menu_book,
      onTap: onTap,
    );
  }
}
