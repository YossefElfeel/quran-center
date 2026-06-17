import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_scaffold.dart';

/// شاشة الدخول — placeholder في Phase 0 (هتتبني كامل في Phase 1:
/// رقم موبايل + باسورد + كود دعوة).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'تسجيل الدخول',
      body: Center(child: Text('شاشة الدخول هتتبني في Phase 1')),
    );
  }
}
