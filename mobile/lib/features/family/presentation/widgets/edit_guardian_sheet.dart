import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_search_picker.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/family_repository.dart';
import '../../domain/guardian_link_row.dart';
import '../../domain/household_option.dart';
import '../controllers/guardian_links_controller.dart';

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
  late String _relation = widget.row.relation;
  late String? _householdId = widget.row.householdId;
  late String? _householdName = widget.row.householdName;
  bool _loading = true;
  bool _busy = false;
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
          _error = 'تعذّر تحميل البيانات';
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
    setState(() {
      _busy = true;
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
        AppSnackbar.success(context, 'بيانات ولي الأمر اتحفظت');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر حفظ البيانات — جرّب تاني');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _loading
      ? const Center(child: CircularProgressIndicator())
      : Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppTextField(
                controller: _name,
                label: 'اسم ولي الأمر',
                enabled: !_busy,
                validator: (s) =>
                    s == null || s.trim().length < 2 ? 'اكتب الاسم' : null,
              ),
              AppTextField(
                controller: _phone,
                label: 'رقم الهاتف',
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                validator: (s) =>
                    s != null &&
                        s.isNotEmpty &&
                        !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(s)
                    ? 'رقم الهاتف من ١٠ إلى ١٥ رقم'
                    : null,
              ),
              AppSelectField<String>(
                label: 'صلة القرابة',
                value: _relation,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'father', child: Text('أب')),
                  DropdownMenuItem(value: 'mother', child: Text('أم')),
                  DropdownMenuItem(value: 'other', child: Text('ولي أمر')),
                ],
                onChanged: _busy ? null : (v) => setState(() => _relation = v!),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        try {
                          final selected =
                              await showAppServerSearchPicker<HouseholdOption>(
                                context: context,
                                title: 'اختار الأسرة',
                                searchLabel: 'بحث باسم الأسرة أو الهاتف',
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
                            AppSnackbar.error(context, 'تعذّر تحميل الأسر');
                          }
                        }
                      },
                child: Text(_householdName ?? 'اختار أسرة موجودة'),
              ),
              if (_householdId == null)
                AppTextField(
                  controller: _newHousehold,
                  label: 'اسم الأسرة الجديدة',
                  enabled: !_busy,
                  validator: (s) => s == null || s.trim().isEmpty
                      ? 'اكتب اسم الأسرة أو اختار أسرة موجودة'
                      : null,
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              AppButton(
                label: 'حفظ البيانات',
                isLoading: _busy,
                onPressed: _save,
              ),
            ],
          ),
        );
}
