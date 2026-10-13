import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_confirm_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
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
    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l.ppGirlMediaConsent,
              style: AppTextStyles.labelSm.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l.ppGirlMediaConsentNote,
              style: AppTextStyles.labelSm.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            state.when(
              skipLoadingOnReload: true,
              loading: () => const LinearProgressIndicator(),
              error: (Object e, StackTrace _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        l.ppConsentsLoadError,
                        style: TextStyle(color: context.palette.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(
                        childConsentsControllerProvider(studentPersonId),
                      ),
                      child: Text(l.retry),
                    ),
                  ],
                ),
              ),
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

class _ConsentSwitch extends ConsumerStatefulWidget {
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
  ConsumerState<_ConsentSwitch> createState() => _ConsentSwitchState();
}

class _ConsentSwitchState extends ConsumerState<_ConsentSwitch> {
  bool _busy = false;
  String get studentPersonId => widget.studentPersonId;
  String get scope => widget.scope;
  String get label => widget.label;
  bool get granted => widget.granted;
  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      value: granted,
      onChanged: _busy
          ? null
          : (bool v) async {
              if (_busy) return;
              setState(() => _busy = true);
              try {
                if (!v &&
                    !await showAppConfirmSheet(
                      context: context,
                      title: l.ppWithdrawConsentTitle,
                      message: l.ppWithdrawConsentMessage,
                      confirmLabel: l.ppWithdrawConsentConfirm,
                    )) {
                  return;
                }
                try {
                  await ref
                      .read(
                        childConsentsControllerProvider(
                          studentPersonId,
                        ).notifier,
                      )
                      .setConsent(scope: scope, granted: v);
                  if (context.mounted) {
                    AppSnackbar.success(
                      context,
                      v ? l.ppConsentGranted : l.ppConsentWithdrawn,
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    AppSnackbar.error(context, l.ppConsentUpdateError);
                  }
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
    );
  }
}
