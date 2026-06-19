import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../domain/circle.dart';

/// بلاطة حلقة (المعلّم + السعة + الحالة).
class CircleTile extends StatelessWidget {
  const CircleTile({required this.circle, required this.onTap, super.key});

  final Circle circle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return AppListCard(
      leadingIcon: Icons.groups,
      title: circle.name,
      subtitle: l.admCircleSubtitle(
        circle.teacherName ?? l.admNoTeacher,
        arabicNumber(circle.maxSize),
      ),
      trailing: AppStatusBadge(
        label: circle.status.labelAr,
        kind: _kind(circle.status),
      ),
      onTap: onTap,
    );
  }

  AppStatusKind _kind(CircleStatus status) => switch (status) {
    CircleStatus.forming => AppStatusKind.info,
    CircleStatus.active => AppStatusKind.success,
    CircleStatus.graduated => AppStatusKind.neutral,
  };
}
