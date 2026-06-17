import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
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

  Future<void> _save() async {
    final String? circleId = _circleId;
    if (circleId == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(waitingListControllerProvider.notifier).enroll(
            waitingId: widget.waitingId,
            studentPersonId: widget.studentPersonId,
            circleId: circleId,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مش قادرين نسند المتقدّم — جرّب تاني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CircleOption>> circles =
        ref.watch(circlesOfLevelProvider(widget.levelId));
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'إسناد لحلقة',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          circles.when(
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace _) =>
                const Text('مش قادرين نحمّل الحلقات'),
            data: (List<CircleOption> list) => list.isEmpty
                ? const Text('مفيش حلقات في المستوى ده لسه')
                : DropdownButton<String>(
                    isExpanded: true,
                    value: _circleId,
                    hint: const Text('اختر الحلقة'),
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
            label: _saving ? 'بنسند…' : 'تأكيد الإسناد',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
