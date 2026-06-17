import 'package:flutter/material.dart';

import '../../../../shared/theme/tokens.dart';
import '../../domain/enrolled_student.dart';
import '../../domain/gender.dart';

/// بلاطة طالب في روستر الحلقة.
class StudentTile extends StatelessWidget {
  const StudentTile({required this.student, super.key});

  final EnrolledStudent student;

  @override
  Widget build(BuildContext context) {
    final bool isGirl = student.gender == Gender.female;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: Icon(isGirl ? Icons.girl : Icons.boy),
        ),
        title: Text(student.name),
        subtitle: Text(student.gender?.labelAr ?? '—'),
      ),
    );
  }
}
