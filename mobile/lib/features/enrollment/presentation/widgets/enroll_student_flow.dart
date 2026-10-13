import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_search_picker.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../family/presentation/widgets/add_guardian_link_sheet.dart';
import 'add_student_sheet.dart';

Future<void> enrollStudentFlow(
  BuildContext context,
  WidgetRef ref, {
  String? circleId,
}) async {
  try {
    Map<String, dynamic>? circle;
    if (circleId == null) {
      final List<Map<String, dynamic>> circles = await ref
          .read(supabaseClientProvider)
          .from('circle')
          .select(
            'id,name,max_size,level:level_id(name,curriculum:curriculum_id(name)),enrollment(count)',
          )
          .neq('status', 'graduated')
          .eq('enrollment.status', 'active')
          .order('name');
      if (!context.mounted) return;
      if (circles.isEmpty) {
        AppSnackbar.info(
          context,
          'ضيف منهج ومستوى وحلقة من إعدادات المناهج الأول',
        );
        return;
      }
      circle = await showAppSearchPicker<Map<String, dynamic>>(
        context: context,
        title: 'اختار الحلقة',
        items: circles,
        label: (Map<String, dynamic> c) {
          final Map<String, dynamic>? level =
              c['level'] as Map<String, dynamic>?;
          final Map<String, dynamic>? curriculum =
              level?['curriculum'] as Map<String, dynamic>?;
          final List<dynamic> count =
              c['enrollment'] as List<dynamic>? ?? <dynamic>[];
          return '${curriculum?['name'] ?? ''} / ${level?['name'] ?? ''} / ${c['name']} — ${count.isEmpty ? 0 : (count.first as Map<String, dynamic>)['count']}/${c['max_size']} طالب';
        },
      );
      if (circle == null || !context.mounted) return;
    } else {
      circle = <String, dynamic>{'id': circleId};
    }
    if (!context.mounted) return;
    final Map<String, dynamic> selectedCircle = circle;
    final Map<String, String>? student =
        await showAppModalSheet<Map<String, String>>(
          context: context,
          title: 'تسجيل طالب',
          builder: (_) =>
              AddStudentSheet(circleId: selectedCircle['id'] as String),
        );
    if (student != null && context.mounted) {
      AppSnackbar.success(
        context,
        'الطالب اتسجّل',
        actionLabel: 'ربط ولي أمر',
        onAction: () => showAppModalSheet<void>(
          context: context,
          title: 'إضافة ولي أمر',
          builder: (_) => AddGuardianLinkSheet(
            childPersonId: student['id'],
            childName: student['name'],
          ),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      AppSnackbar.error(
        context,
        'تعذّر تحميل الحلقات أو تسجيل الطالب — جرّب تاني',
      );
    }
  }
}
