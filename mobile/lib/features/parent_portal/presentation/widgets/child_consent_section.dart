import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../controllers/child_consents_controller.dart';

/// بوابة موافقة وسائط البنت — ولي الأمر يسمح/يمنع الصور والفيديو (opt-in).
class ChildConsentSection extends ConsumerWidget {
  const ChildConsentSection({required this.studentPersonId, super.key});

  final String studentPersonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<Set<String>> state = ref.watch(
      childConsentsControllerProvider(studentPersonId),
    );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l.ppGirlMediaConsent,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l.ppGirlMediaConsentNote,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            state.when(
              skipLoadingOnReload: true,
              loading: () => const LinearProgressIndicator(),
              error: (Object e, StackTrace _) => Text(l.ppConsentsLoadError),
              data: (Set<String> active) => Column(
                children: <Widget>[
                  _ConsentSwitch(
                    studentPersonId: studentPersonId,
                    scope: 'photo',
                    label: l.ppAllowPhotos,
                    granted: active.contains('photo'),
                  ),
                  _ConsentSwitch(
                    studentPersonId: studentPersonId,
                    scope: 'video',
                    label: l.ppAllowVideo,
                    granted: active.contains('video'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentSwitch extends ConsumerWidget {
  const _ConsentSwitch({
    required this.studentPersonId,
    required this.scope,
    required this.label,
    required this.granted,
  });

  final String studentPersonId;
  final String scope;
  final String label;
  final bool granted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      value: granted,
      onChanged: (bool v) => ref
          .read(childConsentsControllerProvider(studentPersonId).notifier)
          .setConsent(scope: scope, granted: v),
    );
  }
}
