import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../controllers/login_controller.dart';

/// شاشة الدخول — رقم موبايل + باسورد. مُركِّب رفيع بيحط فورم صغير.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(title: 'تسجيل الدخول', body: _LoginForm());
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(loginControllerProvider.notifier)
        .signIn(email: _email.text.trim(), password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> state = ref.watch(loginControllerProvider);
    ref.listen<AsyncValue<void>>(loginControllerProvider, (
      AsyncValue<void>? prev,
      AsyncValue<void> next,
    ) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل الدخول — اتأكد من الإيميل والباسورد'),
          ),
        );
      }
    });

    final bool loading = state.isLoading;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'الإيميل',
                hintText: 'name@example.com',
              ),
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'اكتب الإيميل' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'الباسورد'),
              validator: (String? v) =>
                  (v == null || v.isEmpty) ? 'اكتب الباسورد' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: loading ? 'بنحاول…' : 'دخول',
              onPressed: loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
