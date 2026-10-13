import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import 'app_button.dart';
import 'app_snackbar.dart';

/// Keeps a validated form open on failure and prevents duplicate submissions.
class AppAsyncFormSheet extends StatefulWidget {
  const AppAsyncFormSheet({
    required this.fields,
    required this.onSubmit,
    required this.submitLabel,
    required this.successMessage,
    super.key,
  });
  final List<Widget> fields;
  final Future<void> Function() onSubmit;
  final String submitLabel, successMessage;
  @override
  State<AppAsyncFormSheet> createState() => _AppAsyncFormSheetState();
}

class _AppAsyncFormSheetState extends State<AppAsyncFormSheet> {
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;
  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit();
      if (mounted) {
        AppSnackbar.success(context, widget.successMessage);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).commonSaveFailedKeepData);
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
      children: [
        for (final field in widget.fields)
          Padding(padding: const EdgeInsets.only(bottom: 16), child: field),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        AppButton(
          label: widget.submitLabel,
          isLoading: _busy,
          onPressed: _save,
        ),
      ],
    ),
  );
}
