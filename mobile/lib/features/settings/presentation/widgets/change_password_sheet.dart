import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';

class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});
  @override
  ConsumerState<ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  bool _busy = false, _visible = false;
  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppTextField(
          controller: _password,
          label: 'كلمة السر الجديدة',
          obscureText: !_visible,
          autofillHints: const [AutofillHints.newPassword],
          validator: (String? v) =>
              v == null || v.length < 8 ? '٨ أحرف على الأقل' : null,
          suffix: IconButton(
            tooltip: _visible ? 'إخفاء كلمة السر' : 'إظهار كلمة السر',
            icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _visible = !_visible),
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _confirm,
          label: 'تأكيد كلمة السر',
          obscureText: !_visible,
          validator: (String? v) =>
              v != _password.text ? 'كلمتا السر مختلفتين' : null,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'حفظ كلمة السر',
          isLoading: _busy,
          onPressed: () async {
            if (_busy || !_form.currentState!.validate()) return;
            setState(() => _busy = true);
            try {
              await ref
                  .read(supabaseClientProvider)
                  .auth
                  .updateUser(UserAttributes(password: _password.text));
              if (context.mounted) {
                AppSnackbar.success(context, 'كلمة السر اتغيّرت');
                Navigator.of(context).pop();
              }
            } catch (_) {
              if (context.mounted) {
                AppSnackbar.error(
                  context,
                  'تعذّر تغيير كلمة السر — جرّب تاني أو استخدم الاستعادة',
                );
              }
            } finally {
              if (mounted) setState(() => _busy = false);
            }
          },
        ),
      ],
    ),
  );
}
