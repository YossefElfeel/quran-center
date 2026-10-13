import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/presentation/domain_labels.dart';
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
      subtitle: curriculum.type.label(AppL10n.of(context)),
      leadingIcon: Icons.menu_book,
      onTap: onTap,
    );
  }
}
