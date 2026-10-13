import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        FilteringTextInputFormatter,
        LengthLimitingTextInputFormatter,
        TextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../shared/presentation/exception_message.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/gender.dart';
import '../../domain/national_id.dart';
import '../controllers/circle_roster_controller.dart';
import 'national_id_scan_sheet.dart';

/// شيت تسجيل طالب جديد (اسم + نوع + رقم قومي اختياري مع مسح بالكاميرا).
class AddStudentSheet extends ConsumerStatefulWidget {
  const AddStudentSheet({required this.circleId, super.key});

  final String circleId;

  @override
  ConsumerState<AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends ConsumerState<AddStudentSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _natId = TextEditingController();
  Gender _gender = Gender.male;
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _natId.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final String? id = await showAppModalSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => const NationalIdScanSheet(),
    );
    if (id != null && mounted) _natId.text = id;
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    final AppL10n l = AppL10n.of(context);
    final String name = _name.text.trim();
    if (name.isEmpty) return;
    final String natId = _natId.text.trim();
    if (natId.isNotEmpty && !isValidNationalId(natId)) {
      AppSnackbar.error(context, l.enrNationalIdLengthError);
      return;
    }
    setState(() => _saving = true);
    try {
      final String studentId = await ref
          .read(circleRosterControllerProvider(widget.circleId).notifier)
          .addStudent(
            name: name,
            gender: _gender,
            nationalId: natId.isEmpty ? null : natId,
          );
      if (mounted) {
        Navigator.of(
          context,
        ).pop(<String, String>{'id': studentId, 'name': name});
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, e.localizedMessage(AppL10n.of(context)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, l.enrSaveStudentError);
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
            label: l.enrStudentNameLabel,
            validator: (String? v) =>
                v == null || v.trim().isEmpty ? 'املا الحقل ده' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _natId,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]')),
              LengthLimitingTextInputFormatter(14),
            ],
            decoration: InputDecoration(
              labelText: l.enrNationalIdLabel,
              suffixIcon: IconButton(
                tooltip: l.enrScanWithCamera,
                icon: const Icon(Icons.document_scanner),
                onPressed: _openScanner,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<Gender>(
            segments: <ButtonSegment<Gender>>[
              ButtonSegment<Gender>(
                value: Gender.male,
                label: Text(l.enrGenderBoy),
              ),
              ButtonSegment<Gender>(
                value: Gender.female,
                label: Text(l.enrGenderGirl),
              ),
            ],
            selected: <Gender>{_gender},
            onSelectionChanged: (Set<Gender> s) =>
                setState(() => _gender = s.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? l.enrSaving : l.enrSave,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
