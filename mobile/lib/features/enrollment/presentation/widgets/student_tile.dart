import 'package:flutter/material.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../domain/enrolled_student.dart';
import '../../domain/gender.dart';

/// بلاطة طالب في روستر الحلقة.
class StudentTile extends StatelessWidget {
  const StudentTile({required this.student, super.key});

  final EnrolledStudent student;

  @override
  Widget build(BuildContext context) {
    final bool isGirl = student.gender == Gender.female;
    return AppListCard(
      leading: CircleAvatar(
        backgroundColor: context.palette.primary,
        foregroundColor: context.palette.onPrimary,
        child: Icon(isGirl ? Icons.girl : Icons.boy),
      ),
      title: student.name,
      subtitle: student.gender?.labelAr ?? '—',
    );
  }
}
