import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/env/env.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../shared/presentation/exception_message.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  bool _visible = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(loginControllerProvider).isLoading ||
        !_form.currentState!.validate()) {
      return;
    }
    await ref
        .read(loginControllerProvider.notifier)
        .signIn(email: _email.text.trim(), password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<void> state = ref.watch(loginControllerProvider);
    ref.listen(loginControllerProvider, (_, AsyncValue<void> next) {
      if (next.hasError && !next.isLoading) {
        final Object? error = next.error;
        AppSnackbar.error(
          context,
          error is AppException
              ? error.localizedMessage(AppL10n.of(context))
              : l.loginFailed,
        );
      }
    });
    return AppScaffold(
      title: l.loginTitle,
      body: AutofillGroup(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              Icon(
                Icons.menu_book_rounded,
                color: context.palette.primary,
                size: 64,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'دار تحفيظ القرآن',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: _email,
                label: l.emailLabel,
                hint: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                autofillHints: const <String>[
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                textInputAction: TextInputAction.next,
                validator: (String? v) =>
                    v == null ||
                        !RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(v.trim())
                    ? 'اكتب إيميل صحيح'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _password,
                label: l.passwordLabel,
                obscureText: !_visible,
                autofillHints: const <String>[AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (String? v) =>
                    v == null || v.isEmpty ? l.passwordRequired : null,
                suffix: IconButton(
                  tooltip: _visible ? 'إخفاء كلمة السر' : 'إظهار كلمة السر',
                  icon: Icon(
                    _visible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _visible = !_visible),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l.signIn,
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              TextButton(
                onPressed: () => showAppModalSheet<void>(
                  context: context,
                  title: 'استعادة كلمة السر',
                  builder: (_) => _ResetPasswordForm(initialEmail: _email.text),
                ),
                child: const Text('نسيت كلمة السر؟'),
              ),
              if (Env.webUrl.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    try {
                      if (!await launchUrl(
                        Uri.parse(Env.webUrl),
                        mode: LaunchMode.externalApplication,
                      )) {
                        throw StateError('launch');
                      }
                    } catch (_) {
                      if (context.mounted) {
                        AppSnackbar.error(context, 'تعذّر فتح الموقع');
                      }
                    }
                  },
                  child: const Text('تصفّح الكورسات والمسابقات'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetPasswordForm extends ConsumerStatefulWidget {
  const _ResetPasswordForm({required this.initialEmail});
  final String initialEmail;
  @override
  ConsumerState<_ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends ConsumerState<_ResetPasswordForm> {
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  bool _busy = false;
  bool _sent = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppException
              ? e.localizedMessage(AppL10n.of(context))
              : 'تعذّر إرسال الطلب — راجع الاتصال وجرّب تاني',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_sent)
          const Text(
            'لو الإيميل مسجّل هيوصلك رابط. راجع الوارد والبريد غير المرغوب فيه.',
          )
        else ...<Widget>[
          AppTextField(
            controller: _email,
            label: 'الإيميل',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _send(),
            validator: (String? v) =>
                v == null ||
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
                ? 'اكتب إيميل صحيح'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'ابعت رابط استعادة',
            isLoading: _busy,
            onPressed: _send,
          ),
        ],
        if (_error != null)
          Text(_error!, style: TextStyle(color: context.palette.error)),
      ],
    ),
  );
}
