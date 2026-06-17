import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';

const Map<String, String> _roleNamesAr = <String, String>{
  'super_admin': 'سوبر أدمن',
  'admin': 'أدمن',
  'supervisor': 'مشرف',
  'teacher': 'معلّم',
  'parent': 'ولي أمر',
};

/// الرئيسية بعد الدخول — بتعرض أدوار المستخدم (بتثبت إن RLS شغّال) + خروج.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<String>> rolesAsync =
        ref.watch(currentRolesProvider);
    return AppScaffold(
      title: 'مركز تحفيظ القرآن',
      actions: <Widget>[
        IconButton(
          tooltip: 'خروج',
          icon: const Icon(Icons.logout),
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
      body: rolesAsync.when(
        loading: () => const AppLoader(message: 'بنحمّل بياناتك…'),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل بياناتك',
          onRetry: () => ref.invalidate(currentRolesProvider),
        ),
        data: (List<String> roles) => _HomeBody(roles: roles),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.roles});

  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('home_body'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.menu_book, size: 64, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'أهلاً بيك',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (roles.isEmpty)
            const Text(
              'لسه مفيش دور متسنّد لحسابك — كلّم الأدمن.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: roles
                  .map((String r) => _RoleChip(role: r))
                  .toList(),
            ),
          if (roles.contains('admin') || roles.contains('super_admin')) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'المناهج والحلقات',
              icon: Icons.account_tree,
              onPressed: () => context.go(Routes.adminCurricula),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'قائمة الانتظار',
              icon: Icons.how_to_reg,
              onPressed: () => context.go(Routes.adminWaiting),
            ),
          ],
          if (roles.contains('teacher')) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'حلقاتي',
              icon: Icons.menu_book,
              onPressed: () => context.go(Routes.teacherCircles),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_roleNamesAr[role] ?? role),
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
    );
  }
}
