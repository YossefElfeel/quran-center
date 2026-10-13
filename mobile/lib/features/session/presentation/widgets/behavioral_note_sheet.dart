import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/today_session_controller.dart';

/// شيت تسجيل ملاحظة سلوك لطالب — مرئية لولي الأمر أو داخلية.
class BehavioralNoteSheet extends ConsumerStatefulWidget {
  const BehavioralNoteSheet({
    required this.circleId,
    required this.studentPersonId,
    required this.studentName,
    super.key,
  });

  final String circleId;
  final String studentPersonId;
  final String studentName;

  @override
  ConsumerState<BehavioralNoteSheet> createState() =>
      _BehavioralNoteSheetState();
}

class _BehavioralNoteSheetState extends ConsumerState<BehavioralNoteSheet> {
  final TextEditingController _text = TextEditingController();
  String _visibility = 'parent';
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    if (_text.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(todaySessionControllerProvider(widget.circleId).notifier)
          .addBehavioralNote(
            studentPersonId: widget.studentPersonId,
            text: _text.text.trim(),
            visibility: _visibility,
          );
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
      AppSnackbar.error(context, AppL10n.of(context).sesNoteSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
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
              l.sesBehavioralNoteTitle(widget.studentName),
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSm,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: SegmentedButton<String>(
                segments: <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'parent',
                    label: Text(l.sesNoteVisibilityParent),
                  ),
                  ButtonSegment<String>(
                    value: 'internal',
                    label: Text(l.sesNoteVisibilityInternal),
                  ),
                ],
                selected: <String>{_visibility},
                onSelectionChanged: (Set<String> s) =>
                    setState(() => _visibility = s.first),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _text,
              validator: (String? v) =>
                  v == null || v.trim().isEmpty ? l.commonFieldRequired : null,
              minLines: 3,
              maxLines: 5,
              hint: l.sesNoteHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _saving ? l.sesNoteSaving : l.sesNoteSave,
              icon: Icons.save,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
