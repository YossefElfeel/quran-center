import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_search_picker.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../user_invite/data/invite_repository.dart';
import '../../../user_invite/presentation/user_invite_labels.dart';
import '../../data/family_repository.dart';
import '../../domain/guardian_link_row.dart';
import '../../domain/household_naming.dart';
import '../../domain/household_option.dart';
import '../../domain/student_option.dart';
import '../controllers/guardian_links_controller.dart';
import '../controllers/students_for_link_controller.dart';
import '../family_labels.dart';

class AddGuardianLinkSheet extends ConsumerStatefulWidget {
  const AddGuardianLinkSheet({this.childPersonId, this.childName, super.key});
  final String? childPersonId;
  final String? childName;
  @override
  ConsumerState<AddGuardianLinkSheet> createState() =>
      _AddGuardianLinkSheetState();
}

class _AddGuardianLinkSheetState extends ConsumerState<AddGuardianLinkSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _householdName = TextEditingController();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late String? _childId = widget.childPersonId;
  late String? _childName = widget.childName;
  String _relation = 'father';
  HouseholdOption? _household;
  bool _saving = false;
  bool _invite = false;
  String? _createdPersonId;
  String? _link;
  String? _error;

  /// آخر اسم أسرة اقترحناه — لو المستخدم كتب اسم بنفسه منغيّروش.
  String _suggestedHousehold = '';

  @override
  void initState() {
    super.initState();
    _name.addListener(_suggestHouseholdName);
  }

  void _suggestHouseholdName() {
    final String current = _householdName.text.trim();
    if (current.isNotEmpty && current != _suggestedHousehold) return;
    final String family = suggestedFamilyName(_name.text);
    final String suggestion = family.isEmpty
        ? ''
        : AppL10n.of(context).famHouseholdSuggestion(family);
    _suggestedHousehold = suggestion;
    if (_householdName.text != suggestion) _householdName.text = suggestion;
  }

  @override
  void dispose() {
    _name.removeListener(_suggestHouseholdName);
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _householdName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final AppL10n l = AppL10n.of(context);
    if (_childId == null) {
      setState(() => _error = l.famChildHint);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Retain the person ID if the invitation fails: retry never creates a second family.
      _createdPersonId ??= await ref
          .read(guardianLinksControllerProvider.notifier)
          .createLink(
            guardianName: _name.text.trim(),
            childPersonId: _childId!,
            relation: _relation,
            phone: _phone.text.trim(),
            householdId: _household?.id,
            newHouseholdName: _householdName.text.trim(),
          );
      if (_invite) {
        final String? link = await ref
            .read(inviteRepositoryProvider)
            .inviteUser(
              email: _email.text.trim(),
              fullName: _name.text.trim(),
              role: 'parent',
              existingPersonId: _createdPersonId,
            );
        if (!mounted) return;
        setState(() => _link = link);
        AppSnackbar.success(context, l.famLinkedWithInvite);
      } else if (mounted) {
        AppSnackbar.success(context, l.famLinkedSuccess);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = _createdPersonId == null
              ? l.famGuardianSaveError
              : l.famInviteFailed(
                  inviteErrorMessage(e, l) ?? l.famInviteRetryHint,
                ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<StudentOption>> students = ref.watch(
      studentsForLinkProvider,
    );
    if (_link != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l.famInviteLinkTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(l.famInviteLinkShareHint),
          SelectableText(_link!, textDirection: TextDirection.ltr),
          AppButton(
            label: l.commonCopyLink,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _link!));
              if (context.mounted) {
                AppSnackbar.success(context, l.commonLinkCopied);
              }
            },
          ),
          TextButton(
            onPressed: () async {
              try {
                if (!await launchUrl(
                  Uri.https('wa.me', '/', <String, String>{'text': _link!}),
                  mode: LaunchMode.externalApplication,
                )) {
                  throw StateError('launch');
                }
              } catch (_) {
                if (context.mounted) {
                  AppSnackbar.error(context, l.commonWhatsappOpenError);
                }
              }
            },
            child: Text(l.commonShareWhatsapp),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.famDone),
          ),
        ],
      );
    }
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            controller: _name,
            enabled: _createdPersonId == null,
            label: l.famGuardianNameLabel,
            validator: (String? v) =>
                v == null || v.trim().isEmpty ? l.commonNameRequired : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _phone,
            enabled: _createdPersonId == null,
            label: l.famMobileLabel,
            keyboardType: TextInputType.phone,
            validator: (String? v) =>
                v == null ||
                    !RegExp(
                      r'^\+?[0-9]{10,15}$',
                    ).hasMatch(v.replaceAll(' ', ''))
                ? l.famMobileInvalid
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          students.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => AppErrorView(
              message: l.famStudentsLoadFailed,
              onRetry: () => ref.invalidate(studentsForLinkProvider),
            ),
            data: (List<StudentOption> list) => OutlinedButton(
              onPressed: _createdPersonId != null
                  ? null
                  : () async {
                      final StudentOption? student =
                          await showAppSearchPicker<StudentOption>(
                            context: context,
                            title: l.famChildHint,
                            items: list,
                            label: (StudentOption s) => s.fullName,
                          );
                      if (student != null && mounted) {
                        setState(() {
                          _childId = student.personId;
                          _childName = student.fullName;
                        });
                      }
                    },
              child: Text(_childName ?? l.famChildHint),
            ),
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
            onChanged: _createdPersonId != null
                ? null
                : (String? v) => setState(() => _relation = v ?? 'father'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: _createdPersonId != null
                ? null
                : () async {
                    final HouseholdOption? h =
                        await showAppServerSearchPicker<HouseholdOption>(
                          context: context,
                          title: l.famHouseholdTitle,
                          searchLabel: l.famHouseholdSearchLabel,
                          search: (query) async => <HouseholdOption>[
                            HouseholdOption(id: '', name: l.famCreateHousehold),
                            ...await ref
                                .read(familyRepositoryProvider)
                                .searchHouseholds(query),
                          ],
                          label: (HouseholdOption h) => h.name,
                        );
                    if (h != null && mounted) {
                      setState(() => _household = h.id.isEmpty ? null : h);
                    }
                  },
            child: Text(_household?.name ?? l.famCreateHousehold),
          ),
          if (_household == null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _householdName,
              enabled: _createdPersonId == null,
              label: l.famHouseholdNameLabel,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.famCreateLoginInvite),
            value: _invite,
            onChanged: _saving ? null : (bool v) => setState(() => _invite = v),
          ),
          if (_invite)
            AppTextField(
              controller: _email,
              label: l.famGuardianEmailLabel,
              keyboardType: TextInputType.emailAddress,
              validator: (String? v) =>
                  v == null ||
                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
                  ? l.commonEmailInvalid
                  : null,
            ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: TextStyle(color: context.palette.error)),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _createdPersonId == null
                ? l.famSaveGuardian
                : l.famRetryInvite,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
