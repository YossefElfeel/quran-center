import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
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
      final AppL10n l = AppL10n.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.famLinkSaveError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
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
          Text(
            l.famLinkSheetTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.famGuardianNameLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(l.famChildLabel),
          ),
          students.when(
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace _) => AppErrorView(
              message: l.famStudentsLoadError,
              onRetry: () => ref.invalidate(studentsForLinkProvider),
            ),
            data: (List<StudentOption> list) => DropdownButton<String>(
              isExpanded: true,
              value: _childId,
              hint: Text(l.famChildHint),
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
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(l.famRelationLabel),
          ),
          DropdownButton<String>(
            isExpanded: true,
            value: _relation,
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: 'father',
                child: Text(l.famRelationFather),
              ),
              DropdownMenuItem<String>(
                value: 'mother',
                child: Text(l.famRelationMother),
              ),
              DropdownMenuItem<String>(
                value: 'other',
                child: Text(l.famRelationOther),
              ),
            ],
            onChanged: (String? v) => setState(() => _relation = v ?? 'father'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? l.famSaving : l.famLinkAction,
            icon: Icons.link,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
