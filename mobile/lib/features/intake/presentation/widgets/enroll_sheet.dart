import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/circle_option.dart';
import '../controllers/waiting_list_controller.dart';

/// شيت إسناد متقدّم لحلقة من حلقات مستواه.
class EnrollSheet extends ConsumerStatefulWidget {
  const EnrollSheet({
    required this.waitingId,
    required this.studentPersonId,
    required this.levelId,
    super.key,
  });

  final String waitingId;
  final String studentPersonId;
  final String levelId;

  @override
  ConsumerState<EnrollSheet> createState() => _EnrollSheetState();
}

class _EnrollSheetState extends ConsumerState<EnrollSheet> {
  String? _circleId;
  bool _saving = false;

  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    final String? circleId = _circleId;
    if (circleId == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(waitingListControllerProvider.notifier)
          .enroll(
            waitingId: widget.waitingId,
            studentPersonId: widget.studentPersonId,
            circleId: circleId,
          );
      if (mounted) {
        AppSnackbar.success(context, AppL10n.of(context).itkStudentPlaced);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      final AppL10n l = AppL10n.of(context);
      AppSnackbar.error(context, l.itkEnrollError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<CircleOption>> circles = ref.watch(
      circlesOfLevelProvider(widget.levelId),
    );
    final bool hasChoices = circles.asData?.value.isNotEmpty ?? false;
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          circles.when(
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace _) => AppErrorView(
              message: l.itkCirclesLoadError,
              onRetry: () =>
                  ref.invalidate(circlesOfLevelProvider(widget.levelId)),
            ),
            data: (List<CircleOption> list) => list.isEmpty
                ? Text(l.itkNoCirclesInLevel)
                : AppSelectField<String>(
                    label: l.itkAssignToCircle,
                    value: _circleId,
                    hint: l.itkChooseCircle,
                    validator: (String? v) =>
                        v == null ? l.itkChooseCircle : null,
                    items: list
                        .map(
                          (CircleOption c) => DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (String? v) => setState(() => _circleId = v),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? l.itkAssigning : l.itkConfirmAssignment,
            // مقفول لحد ما يختار حلقة (بدل الرجوع الصامت).
            onPressed: _saving || !hasChoices || _circleId == null
                ? null
                : _save,
          ),
        ],
      ),
    );
  }
}
