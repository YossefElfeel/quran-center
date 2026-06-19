import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../core/auth/auth_providers.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'app_scaffold.dart';

/// شاشة الحساب الموقوف/المحظور — مسجّل دخول بس من غير هوية (current_person_id()
/// بترجع NULL بسبب الحظر/الإيقاف، فالـ RLS بتمنع قراءة app_user لنفسه). رسالة
/// واضحة + خروج بدل شاشة فاضية/مكسورة.
class AccountSuspendedView extends ConsumerWidget {
  const AccountSuspendedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette palette = context.palette;
    return AppScaffold(
      title: l.appTitle,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.lock_outline, size: 64, color: palette.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                l.accountSuspendedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.accountSuspendedMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l.logout,
                icon: Icons.logout,
                expanded: false,
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
