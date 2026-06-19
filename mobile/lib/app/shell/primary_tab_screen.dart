import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../core/auth/auth_providers.dart';
import '../../features/parent_portal/presentation/screens/children_screen.dart';
import '../../features/recognition/presentation/screens/honor_board_screen.dart';
import '../../features/session/presentation/screens/my_circles_screen.dart';
import '../../features/supervisor_eval/presentation/screens/eval_circles_screen.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loader.dart';
import '../../shared/widgets/app_scaffold.dart';

const List<String> _supervisorRoles = <String>[
  'supervisor',
  'admin',
  'super_admin',
];

/// التبويب الأساسي — بيعرض شاشة مختلفة حسب دور المستخدم (يحافظ على ثبات عدد
/// الفروع في الـ shell). الأولوية: معلّم → ولي أمر → مشرف/أدمن → لوحة الشرف.
class PrimaryTabScreen extends ConsumerWidget {
  const PrimaryTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<String>> rolesAsync = ref.watch(currentRolesProvider);

    return rolesAsync.when(
      loading: () => AppScaffold(
        title: l.appTitle,
        body: AppLoader(message: l.loading),
      ),
      error: (Object e, StackTrace _) => AppScaffold(
        title: l.appTitle,
        body: AppErrorView(
          message: l.genericError,
          onRetry: () => ref.invalidate(currentRolesProvider),
        ),
      ),
      data: (List<String> roles) {
        if (roles.contains('teacher')) return const MyCirclesScreen();
        if (roles.contains('parent')) return const ChildrenScreen();
        if (roles.any(_supervisorRoles.contains)) {
          return const EvalCirclesScreen();
        }
        return const HonorBoardScreen();
      },
    );
  }
}
