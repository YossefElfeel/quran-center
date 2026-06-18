import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        FilteringTextInputFormatter,
        LengthLimitingTextInputFormatter,
        TextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
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
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _natId.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final String? id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => const NationalIdScanSheet(),
    );
    if (id != null && mounted) _natId.text = id;
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) return;
    final String natId = _natId.text.trim();
    if (natId.isNotEmpty && !isValidNationalId(natId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرقم القومي لازم يكون ١٤ رقم')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(circleRosterControllerProvider(widget.circleId).notifier)
          .addStudent(
            name: name,
            gender: _gender,
            nationalId: natId.isEmpty ? null : natId,
          );
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مش قادرين نسجّل الطالب — جرّب تاني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            'تسجيل طالب',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'اسم الطالب'),
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
              labelText: 'الرقم القومي (اختياري)',
              suffixIcon: IconButton(
                tooltip: 'مسح بالكاميرا',
                icon: const Icon(Icons.document_scanner),
                onPressed: _openScanner,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<Gender>(
            segments: const <ButtonSegment<Gender>>[
              ButtonSegment<Gender>(value: Gender.male, label: Text('ولد')),
              ButtonSegment<Gender>(value: Gender.female, label: Text('بنت')),
            ],
            selected: <Gender>{_gender},
            onSelectionChanged: (Set<Gender> s) =>
                setState(() => _gender = s.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? 'بنسجّل…' : 'حفظ',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
