import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/theme_mode_provider.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_section_header.dart';

/// شاشة الإعدادات — المظهر + الخروج.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _themeLabel(AppL10n l, AppThemeChoice c) {
    switch (c) {
      case AppThemeChoice.system:
        return l.themeSystem;
      case AppThemeChoice.light:
        return l.themeLight;
      case AppThemeChoice.dark:
        return l.themeDark;
      case AppThemeChoice.amoled:
        return l.themeAmoled;
    }
  }

  IconData _themeIcon(AppThemeChoice c) {
    switch (c) {
      case AppThemeChoice.system:
        return Icons.brightness_auto;
      case AppThemeChoice.light:
        return Icons.light_mode;
      case AppThemeChoice.dark:
        return Icons.dark_mode;
      case AppThemeChoice.amoled:
        return Icons.contrast;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final AppThemeChoice current = ref.watch(themeChoiceProvider);

    return AppScaffold(
      title: l.settingsTitle,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: <Widget>[
          AppSectionHeader(title: l.settingsTheme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: RadioGroup<AppThemeChoice>(
                groupValue: current,
                onChanged: (AppThemeChoice? v) {
                  if (v != null) {
                    ref.read(themeChoiceProvider.notifier).set(v);
                  }
                },
                child: Column(
                  children: <Widget>[
                    for (final AppThemeChoice c in AppThemeChoice.values)
                      RadioListTile<AppThemeChoice>(
                        value: c,
                        secondary: Icon(_themeIcon(c), color: p.primary),
                        title: Text(
                          _themeLabel(l, c),
                          style: AppTextStyles.bodyLg.copyWith(
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AppButton(
              label: l.logout,
              icon: Icons.logout,
              variant: AppButtonVariant.outlined,
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
            ),
          ),
        ],
      ),
    );
  }
}
