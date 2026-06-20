import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
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
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    final String? levelId = _levelId;
    if (name.isEmpty || levelId == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(waitingListControllerProvider.notifier)
          .addApplicant(name: name, gender: _gender, levelId: levelId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      final AppL10n l = AppL10n.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.itkAddApplicantError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<LevelOption>> levels = ref.watch(
      levelOptionsProvider,
    );
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l.itkNewApplicant,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(controller: _name, label: l.itkApplicantNameLabel),
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
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(l.itkTargetLevel),
          ),
          levels.when(
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace _) => AppErrorView(
              message: l.itkLevelsLoadError,
              onRetry: () => ref.invalidate(levelOptionsProvider),
            ),
            data: (List<LevelOption> list) => DropdownButton<String>(
              isExpanded: true,
              value: _levelId,
              hint: Text(l.itkChooseLevel),
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
