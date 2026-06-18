import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/person_option.dart';
import '../controllers/all_persons_controller.dart';
import '../controllers/household_members_controller.dart';

/// شيت إضافة فرد لأسرة (شخص موجود + دور).
class AddHouseholdMemberSheet extends ConsumerStatefulWidget {
  const AddHouseholdMemberSheet({required this.householdId, super.key});

  final String householdId;

  @override
  ConsumerState<AddHouseholdMemberSheet> createState() =>
      _AddHouseholdMemberSheetState();
}

class _AddHouseholdMemberSheetState
    extends ConsumerState<AddHouseholdMemberSheet> {
  String? _personId;
  String _role = 'guardian';
  bool _saving = false;

  Future<void> _save() async {
    final String? personId = _personId;
    if (personId == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(householdMembersControllerProvider(widget.householdId).notifier)
          .addMember(personId: personId, role: _role);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مش قادرين نضيف الفرد — جرّب تاني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<PersonOption>> persons = ref.watch(
      allPersonsProvider,
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
            'ضيف فرد للأسرة',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('الشخص'),
          ),
          persons.when(
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace _) =>
                const Text('مش قادرين نحمّل الأشخاص'),
            data: (List<PersonOption> list) => DropdownButton<String>(
              isExpanded: true,
              value: _personId,
              hint: const Text('اختار الشخص'),
              items: list
                  .map(
                    (PersonOption p) => DropdownMenuItem<String>(
                      value: p.personId,
                      child: Text(p.fullName),
                    ),
                  )
                  .toList(),
              onChanged: (String? v) => setState(() => _personId = v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('الدور'),
          ),
          DropdownButton<String>(
            isExpanded: true,
            value: _role,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: 'guardian',
                child: Text('ولي أمر'),
              ),
              DropdownMenuItem<String>(value: 'student', child: Text('طالب')),
            ],
            onChanged: (String? v) => setState(() => _role = v ?? 'guardian'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? 'بنضيف…' : 'ضيف',
            icon: Icons.person_add,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
