import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/settings/settings_repository.dart';
import 'app_button.dart';
import 'app_snackbar.dart';

class CenterContactButton extends ConsumerWidget {
  const CenterContactButton({this.label = 'تواصل مع الإدارة', super.key});
  final String label;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppButton(
    label: label,
    icon: Icons.phone,
    variant: AppButtonVariant.outlined,
    onPressed: () async {
      try {
        final settings = await ref.read(appSettingsProvider.future);
        if (!context.mounted) return;
        if (settings.centerPhone.isEmpty) {
          AppSnackbar.info(
            context,
            'رقم الإدارة مش مضاف — تواصل مع المشرف في الدار',
          );
          return;
        }
        if (!await launchUrl(Uri(scheme: 'tel', path: settings.centerPhone)) &&
            context.mounted) {
          AppSnackbar.info(context, 'رقم الإدارة: ${settings.centerPhone}');
        }
      } catch (_) {
        if (context.mounted) {
          AppSnackbar.error(context, 'تعذّر تحميل رقم الإدارة — جرّب تاني');
        }
      }
    },
  );
}
