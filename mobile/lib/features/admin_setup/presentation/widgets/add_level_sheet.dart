import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/levels_controller.dart';

/// شيت إضافة مستوى (الاسم بس؛ الترتيب تلقائي).
class AddLevelSheet extends ConsumerStatefulWidget {
  const AddLevelSheet({required this.curriculumId, super.key});

  final String curriculumId;

  @override
  ConsumerState<AddLevelSheet> createState() => _AddLevelSheetState();
}

class _AddLevelSheetState extends ConsumerState<AddLevelSheet> {
  final TextEditingController _name = TextEditingController();
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
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(levelsControllerProvider(widget.curriculumId).notifier)
          .add(name);
      if (mounted) {
        AppSnackbar.success(context, 'اتحفظ بنجاح');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, AppL10n.of(context).admLevelSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            controller: _name,
            label: l.admLevelNameLabel,
            validator: (String? v) =>
                v == null || v.trim().isEmpty ? 'املا الحقل ده' : null,
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
