import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
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
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _maxSize.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    final int maxSize = int.tryParse(_maxSize.text.trim()) ?? 30;
    if (name.isEmpty || maxSize <= 0) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(circlesControllerProvider(widget.levelId).notifier)
          .add(name: name, maxSize: maxSize, teacherId: _teacherId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مش قادرين نحفظ الحلقة — جرّب تاني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<TeacherOption>> teachers =
        ref.watch(teacherOptionsProvider);
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
            'حلقة جديدة',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'اسم الحلقة'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _maxSize,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'السعة القصوى'),
          ),
          const SizedBox(height: AppSpacing.md),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('المعلّم'),
          ),
          teachers.when(
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace _) =>
                const Text('مش قادرين نحمّل المعلّمين'),
            data: (List<TeacherOption> list) => DropdownButton<String?>(
              isExpanded: true,
              value: _teacherId,
              hint: const Text('من غير معلّم'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  child: Text('من غير معلّم'),
                ),
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
            label: _saving ? 'بنحفظ…' : 'حفظ',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
