import 'package:flutter/material.dart';
import 'app_button.dart';
import 'app_confirm_sheet.dart';
import 'app_modal_sheet.dart';
import 'app_snackbar.dart';
import 'app_text_field.dart';

class AppApprovalActions extends StatefulWidget {
  const AppApprovalActions({
    required this.onApprove,
    required this.onReturn,
    super.key,
  });
  final Future<void> Function() onApprove;
  final Future<void> Function(String) onReturn;
  @override
  State<AppApprovalActions> createState() => _AppApprovalActionsState();
}

class _AppApprovalActionsState extends State<AppApprovalActions> {
  bool _busy = false;
  Future<void> _decide(bool approve) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (approve) {
        if (!await showAppConfirmSheet(
          context: context,
          title: 'اعتماد التقييم؟',
          message: 'راجع المحتوى قبل الاعتماد',
          confirmLabel: 'اعتماد',
          destructive: false,
        )) {
          return;
        }
        await widget.onApprove();
      } else {
        final String? reason = await showAppModalSheet<String>(
          context: context,
          title: 'رجّعه للمعلّم',
          builder: (_) => const _ReturnReasonForm(),
        );
        if (reason == null) return;
        await widget.onReturn(reason);
      }
      if (mounted) {
        AppSnackbar.success(
          context,
          approve ? 'التقييم اتعتمد' : 'التقييم رجع للمعلّم مع السبب',
        );
      }
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'تعذّر حفظ القرار — جرّب تاني');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: <Widget>[
      AppButton(
        label: 'اعتماد',
        expanded: false,
        isLoading: _busy,
        onPressed: () => _decide(true),
      ),
      AppButton(
        label: 'رجّعه للمعلّم',
        variant: AppButtonVariant.text,
        expanded: false,
        onPressed: _busy ? null : () => _decide(false),
      ),
    ],
  );
}

class _ReturnReasonForm extends StatefulWidget {
  const _ReturnReasonForm();
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
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppTextField(
          controller: _reason,
          label: 'سبب الإرجاع',
          maxLines: 3,
          validator: (String? v) =>
              v == null || v.trim().isEmpty ? 'اكتب المطلوب تعديله' : null,
        ),
        AppButton(
          label: 'إرجاع التقييم',
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
