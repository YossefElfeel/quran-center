import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_search_picker.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/subscription_repository.dart';
import '../../domain/person_option.dart';
import '../controllers/household_members_controller.dart';

class AddHouseholdMemberSheet extends ConsumerStatefulWidget {
  const AddHouseholdMemberSheet({required this.householdId, super.key});
  final String householdId;
  @override
  ConsumerState<AddHouseholdMemberSheet> createState() =>
      _AddHouseholdMemberSheetState();
}

class _AddHouseholdMemberSheetState
    extends ConsumerState<AddHouseholdMemberSheet> {
  PersonOption? _person;
  String _role = 'guardian';
  bool _saving = false;
  String? _error;
  Future<void> _save() async {
    if (_saving) return;
    if (_person == null) {
      setState(() => _error = AppL10n.of(context).subsPickMemberRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(householdMembersControllerProvider(widget.householdId).notifier)
          .addMember(personId: _person!.personId, role: _role);
      if (mounted) {
        AppSnackbar.success(context, AppL10n.of(context).subsMemberAdded);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).subsAddMemberFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextButton(
          onPressed: _saving
              ? null
              : () async {
                  final person = await showAppServerSearchPicker<PersonOption>(
                    context: context,
                    title: l.subsPickPerson,
                    search: (q) => ref
                        .read(subscriptionRepositoryProvider)
                        .fetchAllPersons(query: q),
                    label: (p) => p.fullName,
                  );
                  if (person != null && mounted) {
                    setState(() => _person = person);
                  }
                },
          child: Text(_person?.fullName ?? l.subsPickPerson),
        ),
        AppSelectField<String>(
          label: l.subsRoleLabel,
          value: _role,
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem(
              value: 'guardian',
              child: Text(l.subsRoleGuardian),
            ),
            DropdownMenuItem(value: 'student', child: Text(l.subsRoleStudent)),
          ],
          onChanged: _saving ? null : (v) => setState(() => _role = v!),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        AppButton(
          label: l.subsAddMemberButton,
          isLoading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
