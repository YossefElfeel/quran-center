import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../shared/presentation/exception_message.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/invite_repository.dart';

class InviteUserScreen extends ConsumerStatefulWidget {
  const InviteUserScreen({
    this.existingPersonId,
    this.existingName,
    this.existingRole,
    super.key,
  });
  final String? existingPersonId;
  final String? existingName;
  final String? existingRole;
  @override
  ConsumerState<InviteUserScreen> createState() => _InviteUserScreenState();
}

class _InviteUserScreenState extends ConsumerState<InviteUserScreen> {
  final TextEditingController _email = TextEditingController();
  late final TextEditingController _name = TextEditingController(
    text: widget.existingName,
  );
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late String _role = widget.existingRole ?? 'teacher';
  bool _busy = false;
  String? _link;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final String? link = await ref
          .read(inviteRepositoryProvider)
          .inviteUser(
            email: _email.text.trim(),
            fullName: _name.text.trim(),
            role: _role,
            existingPersonId: widget.existingPersonId,
          );
      if (mounted) setState(() => _link = link);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppException
              ? e.localizedMessage(AppL10n.of(context))
              : 'تعذّر إنشاء الدعوة — جرّب تاني',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'دعوة مستخدم',
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          if (widget.existingPersonId == null)
            const Text('لأولياء الأمور استخدم «إضافة ولي أمر» من بطاقة الطالب'),
          const SizedBox(height: 16),
          AppTextField(
            controller: _name,
            enabled: widget.existingPersonId == null,
            label: 'الاسم',
            validator: (String? v) =>
                v == null || v.trim().isEmpty ? 'اكتب الاسم' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _email,
            label: 'الإيميل',
            keyboardType: TextInputType.emailAddress,
            validator: (String? v) =>
                v == null ||
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
                ? 'اكتب إيميل صحيح'
                : null,
          ),
          const SizedBox(height: 16),
          if (widget.existingRole == null)
            AppSelectField<String>(
              label: 'الدور',
              value: _role,
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'teacher', child: Text('معلّم')),
                DropdownMenuItem(value: 'supervisor', child: Text('مشرف')),
                DropdownMenuItem(value: 'admin', child: Text('مدير')),
              ],
              onChanged: _busy
                  ? null
                  : (String? v) => setState(() => _role = v ?? 'teacher'),
            ),
          const SizedBox(height: 24),
          AppButton(
            label: 'إنشاء رابط دعوة',
            isLoading: _busy,
            onPressed: _invite,
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (_link != null) ...<Widget>[
            const SizedBox(height: 24),
            const Text(
              'رابط الدعوة جاهز — شاركه مع المستخدم عشان يعيّن كلمة السر',
            ),
            SelectableText(_link!, textDirection: TextDirection.ltr),
            AppButton(
              label: 'نسخ الرابط',
              icon: Icons.copy,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _link!));
                if (context.mounted) {
                  AppSnackbar.success(context, 'الرابط اتنسخ');
                }
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('مشاركة عبر واتساب'),
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
                    AppSnackbar.error(
                      context,
                      'تعذّر فتح واتساب — انسخ الرابط',
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    ),
  );
}
