import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/level_option.dart';
import '../controllers/waiting_list_controller.dart';

/// شيت اختبار تحديد المستوى (المشرف): المستوى الناتج + ملاحظات.
class PlacementSheet extends ConsumerStatefulWidget {
  const PlacementSheet({
    required this.waitingId,
    required this.studentPersonId,
    super.key,
  });

  final String waitingId;
  final String studentPersonId;

  @override
  ConsumerState<PlacementSheet> createState() => _PlacementSheetState();
}

class _PlacementSheetState extends ConsumerState<PlacementSheet> {
  final TextEditingController _notes = TextEditingController();
  String? _resultLevelId;
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String? levelId = _resultLevelId;
    if (levelId == null) return;
    setState(() => _saving = true);
    try {
      final String? supervisorId =
          await ref.read(currentPersonIdProvider.future);
      final String notes = _notes.text.trim();
      await ref.read(waitingListControllerProvider.notifier).recordPlacement(
            waitingId: widget.waitingId,
            studentPersonId: widget.studentPersonId,
            supervisorId: supervisorId,
            resultLevelId: levelId,
            notes: notes.isEmpty ? null : notes,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مش قادرين نحفظ الاختبار — جرّب تاني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<LevelOption>> levels =
        ref.watch(levelOptionsProvider);
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
            'اختبار تحديد المستوى',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('المستوى الناتج'),
          ),
          levels.when(
            loading: () => const LinearProgressIndicator(),
            error: (Object e, StackTrace _) =>
                const Text('مش قادرين نحمّل المستويات'),
            data: (List<LevelOption> list) => DropdownButton<String>(
              isExpanded: true,
              value: _resultLevelId,
              hint: const Text('اختر المستوى'),
              items: list
                  .map(
                    (LevelOption l) => DropdownMenuItem<String>(
                      value: l.id,
                      child: Text(l.label),
                    ),
                  )
                  .toList(),
              onChanged: (String? v) => setState(() => _resultLevelId = v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? 'بنحفظ…' : 'حفظ',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
