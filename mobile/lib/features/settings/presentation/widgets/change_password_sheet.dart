import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
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
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppTextField(
            controller: _password,
            label: l.settingsNewPasswordLabel,
            obscureText: !_visible,
            autofillHints: const [AutofillHints.newPassword],
            validator: (String? v) =>
                v == null || v.length < 8 ? l.settingsPasswordMinLength : null,
            suffix: IconButton(
              tooltip: _visible ? l.commonHidePassword : l.commonShowPassword,
              icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _visible = !_visible),
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _confirm,
            label: l.settingsConfirmPasswordLabel,
            obscureText: !_visible,
            validator: (String? v) =>
                v != _password.text ? l.settingsPasswordMismatch : null,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: l.settingsSavePassword,
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
                  AppSnackbar.success(context, l.settingsPasswordChanged);
                  Navigator.of(context).pop();
                }
              } catch (_) {
                if (context.mounted) {
                  AppSnackbar.error(context, l.settingsPasswordChangeError);
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
}
