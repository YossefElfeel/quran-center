import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/complaint.dart';
import '../controllers/feedback_controllers.dart';
import '../feedback_labels.dart';

class ComplaintComposeSheet extends ConsumerStatefulWidget {
  const ComplaintComposeSheet({this.complaint, super.key});
  final Complaint? complaint;
  @override
  ConsumerState<ComplaintComposeSheet> createState() =>
      _ComplaintComposeSheetState();
}

class _ComplaintComposeSheetState extends ConsumerState<ComplaintComposeSheet> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _text = TextEditingController(
    text: widget.complaint?.managerResponse ?? '',
  );
  String _category = 'other';
  bool _busy = false;
  bool _sendFailed = false;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _sendFailed = false;
    });
    try {
      final complaint = widget.complaint;
      if (complaint == null) {
        await ref
            .read(myComplaintsProvider.notifier)
            .add(category: _category, body: _text.text.trim());
      } else {
        await ref
            .read(complaintInboxProvider.notifier)
            .respond(complaint.id, _text.text.trim());
      }
      if (mounted) {
        AppSnackbar.success(
          context,
          complaint == null
              ? AppL10n.of(context).fbkComplaintSent
              : AppL10n.of(context).fbkResponseSaved,
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sendFailed = true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.complaint == null)
            AppSelectField<String>(
              label: l.fbkComplaintCategoryLabel,
              value: _category,
              items: complaintCategories
                  .map(
                    (String c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(complaintCategoryLabel(c, l)),
                    ),
                  )
                  .toList(),
              onChanged: _busy ? null : (v) => setState(() => _category = v!),
            ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _text,
            label: widget.complaint == null
                ? l.fbkComplaintDetails
                : l.fbkRespondDialogTitle,
            maxLines: 5,
            enabled: !_busy,
            validator: (s) => s == null || s.trim().isEmpty
                ? l.fbkDetailsRequired
                : s.length > 5000
                ? l.fbkDetailsTooLong
                : null,
          ),
          if (_sendFailed)
            Text(
              l.fbkSendFailedDraftKept,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          AppButton(
            label: widget.complaint == null
                ? l.fbkSubmitComplaint
                : l.fbkSaveResponse,
            isLoading: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
