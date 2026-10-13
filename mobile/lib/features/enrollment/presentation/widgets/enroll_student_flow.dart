import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../family/presentation/widgets/add_guardian_link_sheet.dart';
import '../../domain/enrollable_circle.dart';
import 'add_student_sheet.dart';
import 'enrollable_circle_picker.dart';

/// مسار تسجيل طالب: (اختيار حلقة لو مش محدّدة) ← شيت بيانات الطالب ←
/// سناك نجاح فيه اختصار "ربط ولي أمر".
Future<void> enrollStudentFlow(
  BuildContext context,
  WidgetRef ref, {
  String? circleId,
}) async {
  // نمسك الـ navigator قبل أي await: أكشن السناك ممكن يتنفّذ بعد ما الشاشة
  // اللي فتحت المسار اتقفلت (context مش mounted).
  final NavigatorState navigator = Navigator.of(context);
  String? targetCircleId = circleId;
  if (targetCircleId == null) {
    final EnrollableCircle? picked = await showEnrollableCirclePicker(context);
    if (picked == null || !context.mounted) return;
    targetCircleId = picked.id;
  }
  final String selectedCircleId = targetCircleId;
  final Map<String, String>? student =
      await showAppModalSheet<Map<String, String>>(
        context: context,
        title: AppL10n.of(context).enrEnrollStudent,
        builder: (_) => AddStudentSheet(circleId: selectedCircleId),
      );
  if (student == null || !context.mounted) return;
  final AppL10n l = AppL10n.of(context);
  AppSnackbar.success(
    context,
    l.enrStudentEnrolled,
    actionLabel: l.enrLinkGuardian,
    onAction: () {
      if (!navigator.mounted) return;
      showAppModalSheet<void>(
        context: navigator.context,
        title: l.enrAddGuardianTitle,
        builder: (_) => AddGuardianLinkSheet(
          childPersonId: student['id'],
          childName: student['name'],
        ),
      );
    },
  );
}
