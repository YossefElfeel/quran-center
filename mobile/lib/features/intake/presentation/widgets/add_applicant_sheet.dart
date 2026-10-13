import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../enrollment/domain/gender.dart';
import '../../domain/level_option.dart';
import '../controllers/waiting_list_controller.dart';

/// شيت إضافة متقدّم لقائمة الانتظار (اسم + نوع + مستوى مستهدف).
class AddApplicantSheet extends ConsumerStatefulWidget {
  const AddApplicantSheet({super.key});

  @override
  ConsumerState<AddApplicantSheet> createState() => _AddApplicantSheetState();
}

class _AddApplicantSheetState extends ConsumerState<AddApplicantSheet> {
  final TextEditingController _name = TextEditingController();
  Gender _gender = Gender.male;
  String? _levelId;
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    final String name = _name.text.trim();
    final String? levelId = _levelId;
    // الفاليديتورز بتغطّي الحالتين؛ ده حارس بس.
    if (name.isEmpty || levelId == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(waitingListControllerProvider.notifier)
          .addApplicant(name: name, gender: _gender, levelId: levelId);
      if (mounted) {
        AppSnackbar.success(context, 'اتحفظ بنجاح');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      final AppL10n l = AppL10n.of(context);
      AppSnackbar.error(context, l.itkAddApplicantError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<LevelOption>> levels = ref.watch(
      levelOptionsProvider,
    );
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            controller: _name,
            label: l.itkApplicantNameLabel,
            validator: (String? v) =>
                v == null || v.trim().isEmpty ? 'املا الحقل ده' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<Gender>(
            segments: <ButtonSegment<Gender>>[
              ButtonSegment<Gender>(value: Gender.male, label: Text(l.itkBoy)),
              ButtonSegment<Gender>(
                value: Gender.female,
                label: Text(l.itkGirl),
              ),
            ],
            selected: <Gender>{_gender},
            onSelectionChanged: (Set<Gender> s) =>
                setState(() => _gender = s.first),
          ),
          const SizedBox(height: AppSpacing.md),
          levels.when(
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace _) => AppErrorView(
              message: l.itkLevelsLoadError,
              onRetry: () => ref.invalidate(levelOptionsProvider),
            ),
            data: (List<LevelOption> list) => AppSelectField<String>(
              label: l.itkTargetLevel,
              value: _levelId,
              hint: l.itkChooseLevel,
              validator: (String? v) => v == null ? l.itkChooseLevel : null,
              items: list
                  .map(
                    (LevelOption l) => DropdownMenuItem<String>(
                      value: l.id,
                      child: Text(l.label),
                    ),
                  )
                  .toList(),
              onChanged: (String? v) => setState(() => _levelId = v),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? l.itkSaving : l.itkSave,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
