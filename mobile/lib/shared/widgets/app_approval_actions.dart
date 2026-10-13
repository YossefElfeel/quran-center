import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'app_button.dart';
import 'app_confirm_sheet.dart';
import 'app_modal_sheet.dart';
import 'app_snackbar.dart';
import 'app_text_field.dart';

class AppApprovalActions extends StatefulWidget {
  const AppApprovalActions({
    required this.onApprove,
    required this.onReturn,
    this.subject,
    super.key,
  });
  final Future<void> Function() onApprove;
  final Future<void> Function(String) onReturn;

  /// اسم اللي بيتعتمد في النصوص (معرّف بـ "ال"): "التقييم"، "بند التطوّر"…
  /// لو مش متحدّد بيستخدم [AppL10n.commonApprovalDefaultSubject].
  final String? subject;
  @override
  State<AppApprovalActions> createState() => _AppApprovalActionsState();
}

class _AppApprovalActionsState extends State<AppApprovalActions> {
  bool _busy = false;
  Future<void> _decide(bool approve) async {
    if (_busy) return;
    setState(() => _busy = true);
    final AppL10n l = AppL10n.of(context);
    final String subject = widget.subject ?? l.commonApprovalDefaultSubject;
    try {
      if (approve) {
        if (!await showAppConfirmSheet(
          context: context,
          title: l.commonApproveConfirmTitle(subject),
          message: l.commonApproveConfirmMessage,
          confirmLabel: l.commonApprove,
          destructive: false,
        )) {
          return;
        }
        await widget.onApprove();
      } else {
        final String? reason = await showAppModalSheet<String>(
          context: context,
          title: l.commonReturnToTeacher,
          builder: (_) => _ReturnReasonForm(subject: subject),
        );
        if (reason == null) return;
        await widget.onReturn(reason);
      }
      if (mounted) {
        AppSnackbar.success(
          context,
          approve
              ? l.commonApprovedSnack(subject)
              : l.commonReturnedSnack(subject),
        );
      }
    } catch (_) {
      if (mounted) AppSnackbar.error(context, l.commonDecisionSaveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Wrap(
      spacing: 8,
      children: <Widget>[
        AppButton(
          label: l.commonApprove,
          expanded: false,
          isLoading: _busy,
          onPressed: () => _decide(true),
        ),
        AppButton(
          label: l.commonReturnToTeacher,
          variant: AppButtonVariant.text,
          expanded: false,
          onPressed: _busy ? null : () => _decide(false),
        ),
      ],
    );
  }
}

class _ReturnReasonForm extends StatefulWidget {
  const _ReturnReasonForm({required this.subject});
  final String subject;
  @override
  State<_ReturnReasonForm> createState() => _ReturnReasonFormState();
}

class _ReturnReasonFormState extends State<_ReturnReasonForm> {
  final TextEditingController _reason = TextEditingController();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppTextField(
            controller: _reason,
            label: l.commonReturnReasonLabel,
            maxLines: 3,
            validator: (String? v) => v == null || v.trim().isEmpty
                ? l.commonReturnReasonRequired
                : null,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: l.commonReturnSubject(widget.subject),
            onPressed: () {
              if (_form.currentState!.validate()) {
                Navigator.of(context).pop(_reason.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }
}
