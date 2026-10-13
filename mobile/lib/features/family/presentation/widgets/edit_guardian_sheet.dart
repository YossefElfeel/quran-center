import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_search_picker.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/family_repository.dart';
import '../../domain/guardian_link_row.dart';
import '../../domain/household_option.dart';
import '../controllers/guardian_links_controller.dart';
import '../family_labels.dart';

class EditGuardianSheet extends ConsumerStatefulWidget {
  const EditGuardianSheet({required this.row, super.key});
  final GuardianLinkRow row;
  @override
  ConsumerState<EditGuardianSheet> createState() => _EditGuardianSheetState();
}

class _EditGuardianSheetState extends ConsumerState<EditGuardianSheet> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.row.guardianName,
  );
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _newHousehold = TextEditingController();
  // Normalised again here so a free-text relation never trips the select
  // field's "value must be one of the items" assertion.
  late String _relation = GuardianLinkRow.normalizeRelation(
    widget.row.relation,
  );
  late String? _householdId = widget.row.householdId;
  late String? _householdName = widget.row.householdName;
  bool _loading = true;
  bool _busy = false;
  // Load failure is a flag (not a message) because _load starts in initState,
  // before localizations can be looked up.
  bool _loadFailed = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final row = await ref
          .read(supabaseClientProvider)
          .from('person')
          .select('phone')
          .eq('id', widget.row.guardianId)
          .single();
      if (mounted) {
        setState(() {
          _phone.text = row['phone'] as String? ?? '';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _newHousehold.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final AppL10n l = AppL10n.of(context);
    setState(() {
      _busy = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      await ref
          .read(supabaseClientProvider)
          .rpc(
            'update_guardian_details',
            params: <String, dynamic>{
              'p_guardian_id': widget.row.guardianId,
              'p_student_id': widget.row.studentId,
              'p_name': _name.text.trim(),
              'p_phone': _phone.text.trim(),
              'p_relation': _relation,
              'p_household_id': _householdId,
              'p_new_household_name': _newHousehold.text.trim(),
            },
          );
      ref.invalidate(guardianLinksControllerProvider);
      if (mounted) {
        AppSnackbar.success(context, l.famGuardianSaved);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) setState(() => _error = l.famDataSaveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final String? error = _loadFailed ? l.famDataLoadError : _error;
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppTextField(
                  controller: _name,
                  label: l.famGuardianNameLabel,
                  enabled: !_busy,
                  validator: (s) => s == null || s.trim().length < 2
                      ? l.commonNameRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _phone,
                  label: l.famPhoneLabel,
                  enabled: !_busy,
                  keyboardType: TextInputType.phone,
                  validator: (s) =>
                      s != null &&
                          s.isNotEmpty &&
                          !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(s)
                      ? l.famPhoneInvalid
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppSelectField<String>(
                  label: l.famRelationLabel,
                  value: _relation,
                  items: <DropdownMenuItem<String>>[
                    for (final String r in GuardianLinkRow.knownRelations)
                      DropdownMenuItem(
                        value: r,
                        child: Text(guardianRelationLabel(r, l)),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _relation = v ?? 'other'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          try {
                            final selected =
                                await showAppServerSearchPicker<
                                  HouseholdOption
                                >(
                                  context: context,
                                  title: l.famPickHousehold,
                                  searchLabel: l.famHouseholdSearchLabel,
                                  search: ref
                                      .read(familyRepositoryProvider)
                                      .searchHouseholds,
                                  label: (h) => h.name,
                                );
                            if (selected != null && mounted) {
                              setState(() {
                                _householdId = selected.id;
                                _householdName = selected.name;
                              });
                            }
                          } catch (_) {
                            if (context.mounted) {
                              AppSnackbar.error(
                                context,
                                l.famHouseholdsLoadFailed,
                              );
                            }
                          }
                        },
                  child: Text(_householdName ?? l.famPickExistingHousehold),
                ),
                if (_householdId == null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _newHousehold,
                    label: l.famNewHouseholdNameLabel,
                    enabled: !_busy,
                    validator: (s) => s == null || s.trim().isEmpty
                        ? l.famHouseholdNameRequired
                        : null,
                  ),
                ],
                if (error != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l.famSaveData,
                  isLoading: _busy,
                  onPressed: _save,
                ),
              ],
            ),
          );
  }
}
