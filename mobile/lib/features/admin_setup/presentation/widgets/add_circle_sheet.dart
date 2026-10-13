import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/teacher_option.dart';
import '../controllers/circles_controller.dart';

/// شيت إضافة حلقة (اسم + سعة + إسناد معلّم اختياري).
class AddCircleSheet extends ConsumerStatefulWidget {
  const AddCircleSheet({required this.levelId, super.key});

  final String levelId;

  @override
  ConsumerState<AddCircleSheet> createState() => _AddCircleSheetState();
}

class _AddCircleSheetState extends ConsumerState<AddCircleSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _maxSize = TextEditingController(text: '30');
  String? _teacherId;
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _maxSize.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    final String name = _name.text.trim();
    // الفاليديتور ضمن إن السعة رقم موجب؛ الفحص هنا للأمان بس.
    final int? maxSize = parseLocalizedInt(_maxSize.text.trim());
    if (name.isEmpty || maxSize == null || maxSize <= 0) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(circlesControllerProvider(widget.levelId).notifier)
          .add(name: name, maxSize: maxSize, teacherId: _teacherId);
      if (mounted) {
        AppSnackbar.success(
          context,
          AppL10n.of(context).commonSavedSuccessfully,
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, AppL10n.of(context).admCircleSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<TeacherOption>> teachers = ref.watch(
      teacherOptionsProvider,
    );
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            controller: _name,
            label: l.admCircleNameLabel,
            validator: (String? v) =>
                v == null || v.trim().isEmpty ? l.commonFieldRequired : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _maxSize,
            keyboardType: TextInputType.number,
            label: l.admCircleMaxSizeLabel,
            validator: (String? v) {
              final int? size = parseLocalizedInt((v ?? '').trim());
              return size == null || size <= 0
                  ? l.admCircleCapacityInvalid
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          teachers.when(
            loading: () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l.admTeacherLabel),
                const SizedBox(height: AppSpacing.sm),
                const LinearProgressIndicator(),
              ],
            ),
            error: (Object e, StackTrace _) => AppErrorView(
              message: l.admTeachersLoadError,
              onRetry: () => ref.invalidate(teacherOptionsProvider),
            ),
            data: (List<TeacherOption> list) => AppSelectField<String?>(
              label: l.admTeacherLabel,
              value: _teacherId,
              hint: l.admNoTeacher,
              items: <DropdownMenuItem<String?>>[
                DropdownMenuItem<String?>(child: Text(l.admNoTeacher)),
                ...list.map(
                  (TeacherOption t) => DropdownMenuItem<String?>(
                    value: t.id,
                    child: Text(t.fullName),
                  ),
                ),
              ],
              onChanged: (String? v) => setState(() => _teacherId = v),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? l.admSaving : l.admSave,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
