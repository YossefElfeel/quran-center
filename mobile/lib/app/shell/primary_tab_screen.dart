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
import '../../shared/widgets/app_segmented_control.dart';

const List<String> _supervisorRoles = <String>[
  'supervisor',
  'admin',
  'super_admin',
];

/// التبويب الأساسي — بيعرض شاشة مختلفة حسب دور المستخدم (يحافظ على ثبات عدد
/// الفروع في الـ shell). الأولوية: معلّم → ولي أمر → مشرف/أدمن → لوحة الشرف.
class PrimaryTabScreen extends ConsumerStatefulWidget {
  const PrimaryTabScreen({super.key});
  @override
  ConsumerState<PrimaryTabScreen> createState() => _PrimaryTabScreenState();
}

class _PrimaryTabScreenState extends ConsumerState<PrimaryTabScreen> {
  bool _review = false;

  @override
  Widget build(BuildContext context) {
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
        if (roles.contains('teacher') && roles.any(_supervisorRoles.contains)) {
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: AppSegmentedControl<bool>(
                  segments: const [
                    (value: false, label: 'حلقاتي'),
                    (value: true, label: 'المراجعات'),
                  ],
                  selected: _review,
                  onChanged: (bool v) => setState(() => _review = v),
                ),
              ),
              Expanded(
                child: _review
                    ? const EvalCirclesScreen()
                    : const MyCirclesScreen(),
              ),
            ],
          );
        }
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
