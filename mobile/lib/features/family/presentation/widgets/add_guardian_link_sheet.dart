import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_search_picker.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../user_invite/data/invite_repository.dart';
import '../../data/family_repository.dart';
import '../../domain/household_option.dart';
import '../../domain/student_option.dart';
import '../controllers/guardian_links_controller.dart';
import '../controllers/students_for_link_controller.dart';

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
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _householdName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_childId == null) {
      setState(() => _error = 'اختار الطفل');
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
        AppSnackbar.success(
          context,
          'ولي الأمر اتربط ورابط الدعوة جاهز للمشاركة',
        );
      } else if (mounted) {
        AppSnackbar.success(context, 'ولي الأمر اتربط بالطفل والأسرة');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _createdPersonId == null
              ? 'تعذّر حفظ ولي الأمر — جرّب تاني'
              : 'ولي الأمر اتحفظ، لكن الدعوة فشلت. جرّب الدعوة تاني بنفس البيانات.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<StudentOption>> students = ref.watch(
      studentsForLinkProvider,
    );
    if (_link != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'رابط دعوة الدخول',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'شارك الرابط مع ولي الأمر عشان يعيّن كلمة السر. الإيميل مش بيتبعت تلقائيًا.',
          ),
          SelectableText(_link!, textDirection: TextDirection.ltr),
          AppButton(
            label: 'نسخ الرابط',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _link!));
              if (context.mounted) AppSnackbar.success(context, 'الرابط اتنسخ');
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
                  AppSnackbar.error(context, 'تعذّر فتح واتساب — انسخ الرابط');
                }
              }
            },
            child: const Text('مشاركة عبر واتساب'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('تمام'),
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
            label: 'اسم ولي الأمر',
            validator: (String? v) =>
                v == null || v.trim().isEmpty ? 'اكتب الاسم' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _phone,
            enabled: _createdPersonId == null,
            label: 'رقم الموبايل',
            keyboardType: TextInputType.phone,
            validator: (String? v) =>
                v == null ||
                    !RegExp(
                      r'^\+?[0-9]{10,15}$',
                    ).hasMatch(v.replaceAll(' ', ''))
                ? 'اكتب رقم صحيح من ١٠ إلى ١٥ رقم'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          students.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => AppErrorView(
              message: 'تعذّر تحميل الطلبة',
              onRetry: () => ref.invalidate(studentsForLinkProvider),
            ),
            data: (List<StudentOption> list) => OutlinedButton(
              onPressed: _createdPersonId != null
                  ? null
                  : () async {
                      final StudentOption? student =
                          await showAppSearchPicker<StudentOption>(
                            context: context,
                            title: 'اختار الطفل',
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
              child: Text(_childName ?? 'اختار الطفل'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSelectField<String>(
            label: 'صلة القرابة',
            value: _relation,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem(value: 'father', child: Text('أب')),
              DropdownMenuItem(value: 'mother', child: Text('أم')),
              DropdownMenuItem(value: 'other', child: Text('ولي أمر')),
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
                          title: 'الأسرة',
                          searchLabel: 'بحث باسم الأسرة أو الهاتف',
                          search: (query) async => <HouseholdOption>[
                            const HouseholdOption(
                              id: '',
                              name: 'إنشاء أسرة جديدة',
                            ),
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
            child: Text(_household?.name ?? 'إنشاء أسرة جديدة'),
          ),
          if (_household == null)
            AppTextField(
              controller: _householdName,
              enabled: _createdPersonId == null,
              label: 'اسم الأسرة (لو فاضي هنستخدم اسم ولي الأمر)',
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('إنشاء دعوة دخول'),
            value: _invite,
            onChanged: _saving ? null : (bool v) => setState(() => _invite = v),
          ),
          if (_invite)
            AppTextField(
              controller: _email,
              label: 'إيميل ولي الأمر',
              keyboardType: TextInputType.emailAddress,
              validator: (String? v) =>
                  v == null ||
                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
                  ? 'اكتب إيميل صحيح'
                  : null,
            ),
          if (_error != null)
            Text(_error!, style: TextStyle(color: context.palette.error)),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _createdPersonId == null
                ? 'حفظ ولي الأمر'
                : 'إعادة محاولة الدعوة',
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
