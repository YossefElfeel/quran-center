import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/shell/sync_status_sheet.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/settings/settings_repository.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/display_prefs.dart';
import '../../../../shared/theme/theme_mode_provider.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_confirm_sheet.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_segmented_control.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../home/presentation/screens/dashboard_screen.dart'
    show homeNameProvider;
import '../controllers/app_version_provider.dart';
import '../widgets/change_password_sheet.dart';

/// شاشة الإعدادات — المظهر + سهولة الوصول + الخروج.
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

  String _sizeLabel(AppL10n l, AppTextSize s) {
    switch (s) {
      case AppTextSize.small:
        return l.textSizeSmall;
      case AppTextSize.normal:
        return l.textSizeNormal;
      case AppTextSize.large:
        return l.textSizeLarge;
      case AppTextSize.xlarge:
        return l.textSizeXLarge;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final AppThemeChoice currentTheme = ref.watch(themeChoiceProvider);
    final AppTextSize textSize = ref.watch(textSizeProvider);
    final bool highContrast = ref.watch(highContrastProvider);

    return AppScaffold(
      title: l.settingsTitle,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: <Widget>[
          AppSectionHeader(title: l.settingsAccountSection),
          ListTile(
            title: ref
                .watch(homeNameProvider)
                .when(
                  data: (name) => Text(name),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => Text(l.settingsNameLoadError),
                ),
            subtitle: Text(l.invNameLabel),
          ),
          ListTile(
            title: Text(
              ref.watch(supabaseClientProvider).auth.currentUser?.email ??
                  l.settingsAccountFallback,
            ),
            subtitle: Text(l.settingsLoginEmail),
          ),
          ListTile(
            leading: const Icon(Icons.password),
            title: Text(l.settingsChangePassword),
            onTap: () => showAppModalSheet<void>(
              context: context,
              title: l.settingsChangePassword,
              builder: (_) => const ChangePasswordSheet(),
            ),
          ),
          // ───────── المظهر ─────────
          AppSectionHeader(title: l.settingsTheme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: RadioGroup<AppThemeChoice>(
                groupValue: currentTheme,
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

          // ───────── سهولة الوصول ─────────
          AppSectionHeader(title: l.settingsAccessibility),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l.settingsTextSize,
                    style: AppTextStyles.labelLg.copyWith(color: p.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSegmentedControl<AppTextSize>(
                    segments: <({AppTextSize value, String label})>[
                      for (final AppTextSize s in AppTextSize.values)
                        (value: s, label: _sizeLabel(l, s)),
                    ],
                    selected: textSize,
                    onChanged: (AppTextSize s) =>
                        ref.read(textSizeProvider.notifier).set(s),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // معاينة حيّة — بتكبر/بتصغر مع الاختيار.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: p.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Text(
                      l.textSizePreview,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLg.copyWith(
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                value: highContrast,
                onChanged: (bool v) =>
                    ref.read(highContrastProvider.notifier).set(v),
                secondary: Icon(Icons.contrast, color: p.primary),
                title: Text(
                  l.settingsHighContrast,
                  style: AppTextStyles.bodyLg.copyWith(color: p.textPrimary),
                ),
                subtitle: Text(
                  l.settingsHighContrastDesc,
                  style: AppTextStyles.bodyMd.copyWith(color: p.textSecondary),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          AppSectionHeader(title: l.settingsSyncSection),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(l.syncStatusTitle),
            onTap: () => SyncStatusSheet.show(context),
          ),
          AppSectionHeader(title: l.settingsAboutSection),
          ListTile(
            title: Text(l.settingsAppVersion),
            subtitle: Text(
              ref
                  .watch(appVersionProvider)
                  .when(
                    data: (String v) => v,
                    loading: () => l.settingsVersionLoading,
                    error: (_, _) => '—',
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: Text(l.commonContactAdmin),
            subtitle: Text(
              ref.watch(appSettingsProvider).asData?.value.centerPhone ?? '',
            ),
            onTap: () async {
              final String phone =
                  ref.read(appSettingsProvider).asData?.value.centerPhone ?? '';
              if (phone.isEmpty) {
                AppSnackbar.info(context, l.settingsAdminPhoneMissing);
                return;
              }
              try {
                if (!await launchUrl(Uri(scheme: 'tel', path: phone))) {
                  throw StateError('launch');
                }
              } catch (_) {
                if (context.mounted) {
                  AppSnackbar.error(context, l.settingsCallFailed(phone));
                }
              }
            },
          ),
          // ───────── الخروج ─────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AppButton(
              label: l.logout,
              icon: Icons.logout,
              variant: AppButtonVariant.outlined,
              onPressed: () async {
                if (!await showAppConfirmSheet(
                  context: context,
                  title: l.settingsLogoutConfirmTitle,
                  confirmLabel: l.settingsLogoutConfirm,
                  message: l.settingsLogoutConfirmMessage,
                )) {
                  return;
                }
                try {
                  await ref.read(authRepositoryProvider).signOut();
                } catch (_) {
                  if (context.mounted) {
                    AppSnackbar.error(context, l.settingsLogoutError);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
