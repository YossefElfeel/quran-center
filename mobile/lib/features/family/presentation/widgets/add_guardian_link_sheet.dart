import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/student_option.dart';
import '../controllers/guardian_links_controller.dart';
import '../controllers/students_for_link_controller.dart';

/// شيت ربط ولي أمر جديد بطفل (بينشئ ولي الأمر بدور parent).
class AddGuardianLinkSheet extends ConsumerStatefulWidget {
  const AddGuardianLinkSheet({super.key});

  @override
  ConsumerState<AddGuardianLinkSheet> createState() =>
      _AddGuardianLinkSheetState();
}

class _AddGuardianLinkSheetState extends ConsumerState<AddGuardianLinkSheet> {
  final TextEditingController _name = TextEditingController();
  String? _childId;
  String _relation = 'father';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    final String? childId = _childId;
    if (name.isEmpty || childId == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(guardianLinksControllerProvider.notifier)
          .createLink(
            guardianName: name,
            childPersonId: childId,
            relation: _relation,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مش قادرين نحفظ الربط — جرّب تاني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<StudentOption>> students = ref.watch(
      studentsForLinkProvider,
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
          const Text(
            'ربط ولي أمر بطفل',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'اسم ولي الأمر'),
          ),
          const SizedBox(height: AppSpacing.md),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('الطفل'),
          ),
          students.when(
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace _) =>
                const Text('مش قادرين نحمّل الطلبة'),
            data: (List<StudentOption> list) => DropdownButton<String>(
              isExpanded: true,
              value: _childId,
              hint: const Text('اختار الطفل'),
              items: list
                  .map(
                    (StudentOption s) => DropdownMenuItem<String>(
                      value: s.personId,
                      child: Text(s.fullName),
                    ),
                  )
                  .toList(),
              onChanged: (String? v) => setState(() => _childId = v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('صلة القرابة'),
          ),
          DropdownButton<String>(
            isExpanded: true,
            value: _relation,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: 'father', child: Text('أب')),
              DropdownMenuItem<String>(value: 'mother', child: Text('أم')),
              DropdownMenuItem<String>(value: 'other', child: Text('غير ذلك')),
            ],
            onChanged: (String? v) => setState(() => _relation = v ?? 'father'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? 'بنحفظ…' : 'ربط',
            icon: Icons.link,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
