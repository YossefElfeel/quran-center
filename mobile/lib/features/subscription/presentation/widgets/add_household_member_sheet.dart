import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/error/app_exception.dart';
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final AppL10n l = AppL10n.of(context);
      final String msg = e is AppException ? e.message : l.subsAddMemberError;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
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
          Text(
            l.subsAddMemberTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(l.subsPersonLabel),
          ),
          persons.when(
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace _) => Text(l.subsPersonsLoadError),
            data: (List<PersonOption> list) => DropdownButton<String>(
              isExpanded: true,
              value: _personId,
              hint: Text(l.subsPickPerson),
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
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(l.subsRoleLabel),
          ),
          DropdownButton<String>(
            isExpanded: true,
            value: _role,
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: 'guardian',
                child: Text(l.subsRoleGuardian),
              ),
              DropdownMenuItem<String>(
                value: 'student',
                child: Text(l.subsRoleStudent),
              ),
            ],
            onChanged: (String? v) => setState(() => _role = v ?? 'guardian'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? l.subsAdding : l.subsAddMemberButton,
            icon: Icons.person_add,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
