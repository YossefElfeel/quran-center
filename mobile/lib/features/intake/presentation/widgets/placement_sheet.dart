import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/level_option.dart';
import '../controllers/waiting_list_controller.dart';

/// شيت اختبار تحديد المستوى (المشرف): المستوى الناتج + ملاحظات.
class PlacementSheet extends ConsumerStatefulWidget {
  const PlacementSheet({
    required this.waitingId,
    required this.studentPersonId,
    super.key,
  });

  final String waitingId;
  final String studentPersonId;

  @override
  ConsumerState<PlacementSheet> createState() => _PlacementSheetState();
}

class _PlacementSheetState extends ConsumerState<PlacementSheet> {
  final TextEditingController _notes = TextEditingController();
  String? _resultLevelId;
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    final String? levelId = _resultLevelId;
    if (levelId == null) return;
    setState(() => _saving = true);
    try {
      final String? supervisorId = await ref.read(
        currentPersonIdProvider.future,
      );
      final String notes = _notes.text.trim();
      await ref
          .read(waitingListControllerProvider.notifier)
          .recordPlacement(
            waitingId: widget.waitingId,
            studentPersonId: widget.studentPersonId,
            supervisorId: supervisorId,
            resultLevelId: levelId,
            notes: notes.isEmpty ? null : notes,
          );
      if (mounted) {
        AppSnackbar.success(context, AppL10n.of(context).itkPlacementSaved);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      final AppL10n l = AppL10n.of(context);
      AppSnackbar.error(context, l.itkPlacementSaveError);
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
          levels.when(
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace _) => AppErrorView(
              message: l.itkLevelsLoadError,
              onRetry: () => ref.invalidate(levelOptionsProvider),
            ),
            data: (List<LevelOption> list) => AppSelectField<String>(
              label: l.itkResultLevel,
              value: _resultLevelId,
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
              onChanged: (String? v) => setState(() => _resultLevelId = v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _notes,
            maxLines: 2,
            label: l.itkNotesOptionalLabel,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? l.itkSaving : l.itkSave,
            // مقفول لحد ما يختار المستوى الناتج (بدل الرجوع الصامت).
            onPressed: _saving || _resultLevelId == null ? null : _save,
          ),
        ],
      ),
    );
  }
}
