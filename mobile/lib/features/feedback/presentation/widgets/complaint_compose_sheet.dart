import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/complaint.dart';
import '../controllers/feedback_controllers.dart';

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
  String? _error;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
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
          complaint == null ? 'الشكوى اتبعتت' : 'الرد اتحفظ',
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'تعذّر الإرسال — كلامك لسه محفوظ هنا، جرّب تاني',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.complaint == null)
          AppSelectField<String>(
            label: 'تصنيف الشكوى',
            value: _category,
            items: complaintCategoriesAr.entries
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            onChanged: _busy ? null : (v) => setState(() => _category = v!),
          ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _text,
          label: widget.complaint == null ? 'تفاصيل الشكوى' : 'الرد على الشكوى',
          maxLines: 5,
          enabled: !_busy,
          validator: (s) => s == null || s.trim().isEmpty
              ? 'اكتب التفاصيل قبل الإرسال'
              : s.length > 5000
              ? 'اكتب تفاصيل أقل من ٥٠٠٠ حرف'
              : null,
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        AppButton(
          label: widget.complaint == null ? 'إرسال الشكوى' : 'حفظ الرد',
          isLoading: _busy,
          onPressed: _save,
        ),
      ],
    ),
  );
}
