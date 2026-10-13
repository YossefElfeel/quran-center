import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
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
    final int? parsedSize = parseLocalizedInt(_maxSize.text.trim());
    if (parsedSize == null || parsedSize <= 0) {
      AppSnackbar.error(context, 'اكتب سعة الحلقة كرقم أكبر من صفر');
      return;
    }
    final int maxSize = parsedSize;
    if (name.isEmpty || maxSize <= 0) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(circlesControllerProvider(widget.levelId).notifier)
          .add(name: name, maxSize: maxSize, teacherId: _teacherId);
      if (mounted) {
        AppSnackbar.success(context, 'اتحفظ بنجاح');
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
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l.admNewCircle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _name,
              label: l.admCircleNameLabel,
              validator: (String? v) =>
                  v == null || v.trim().isEmpty ? 'املا الحقل ده' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _maxSize,
              keyboardType: TextInputType.number,
              label: l.admCircleMaxSizeLabel,
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l.admTeacherLabel),
            ),
            teachers.when(
              loading: () => const LinearProgressIndicator(),
              error: (Object e, StackTrace _) => AppErrorView(
                message: l.admTeachersLoadError,
                onRetry: () => ref.invalidate(teacherOptionsProvider),
              ),
              data: (List<TeacherOption> list) => DropdownButton<String?>(
                isExpanded: true,
                value: _teacherId,
                hint: Text(l.admNoTeacher),
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
      ),
    );
  }
}
