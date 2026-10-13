import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/settings/settings_repository.dart';
import 'app_button.dart';
import 'app_snackbar.dart';

class CenterContactButton extends ConsumerWidget {
  const CenterContactButton({this.label, super.key});

  /// لو مش متحدّد بيستخدم [AppL10n.commonContactAdmin].
  final String? label;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppButton(
    label: label ?? AppL10n.of(context).commonContactAdmin,
    icon: Icons.phone,
    variant: AppButtonVariant.outlined,
    onPressed: () async {
      try {
        final settings = await ref.read(appSettingsProvider.future);
        if (!context.mounted) return;
        if (settings.centerPhone.isEmpty) {
          AppSnackbar.info(
            context,
            AppL10n.of(context).commonAdminPhoneMissing,
          );
          return;
        }
        if (!await launchUrl(Uri(scheme: 'tel', path: settings.centerPhone)) &&
            context.mounted) {
          AppSnackbar.info(
            context,
            AppL10n.of(context).commonAdminPhone(settings.centerPhone),
          );
        }
      } catch (_) {
        if (context.mounted) {
          AppSnackbar.error(
            context,
            AppL10n.of(context).commonAdminPhoneLoadError,
          );
        }
      }
    },
  );
}
