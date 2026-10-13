import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/settings/settings_repository.dart';
import 'app_button.dart';
import 'app_snackbar.dart';

/// زرار "تواصل مع الإدارة" — بيختفي خالص لو رقم الدار مش متسجّل (أو لسه
/// بيتحمّل/فشل تحميله) بدل ما يظهر زرار مالوش لازمة.
class CenterContactButton extends ConsumerWidget {
  const CenterContactButton({this.label, super.key});

  /// لو مش متحدّد بيستخدم [AppL10n.commonContactAdmin].
  final String? label;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String phone =
        ref.watch(appSettingsProvider).asData?.value.centerPhone.trim() ?? '';
    if (phone.isEmpty) return const SizedBox.shrink();
    return AppButton(
      label: label ?? AppL10n.of(context).commonContactAdmin,
      icon: Icons.phone,
      variant: AppButtonVariant.outlined,
      onPressed: () async {
        try {
          if (!await launchUrl(Uri(scheme: 'tel', path: phone)) &&
              context.mounted) {
            AppSnackbar.info(
              context,
              AppL10n.of(context).commonAdminPhone(phone),
            );
          }
        } catch (_) {
          if (context.mounted) {
            AppSnackbar.info(
              context,
              AppL10n.of(context).commonAdminPhone(phone),
            );
          }
        }
      },
    );
  }
}
