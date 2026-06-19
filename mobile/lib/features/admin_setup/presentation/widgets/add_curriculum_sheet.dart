import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/curriculum.dart';
import '../controllers/curricula_controller.dart';

/// شيت إضافة منهج جديد (اسم + نوع).
class AddCurriculumSheet extends ConsumerStatefulWidget {
  const AddCurriculumSheet({super.key});

  @override
  ConsumerState<AddCurriculumSheet> createState() => _AddCurriculumSheetState();
}

class _AddCurriculumSheetState extends ConsumerState<AddCurriculumSheet> {
  final TextEditingController _name = TextEditingController();
  CurriculumType _type = CurriculumType.quran;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(curriculaControllerProvider.notifier)
          .add(name: name, type: _type);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).admCurriculumSaveError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
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
            l.admNewCurriculum,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.admCurriculumNameLabel),
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<CurriculumType>(
            segments: CurriculumType.values
                .map(
                  (CurriculumType t) => ButtonSegment<CurriculumType>(
                    value: t,
                    label: Text(t.labelAr),
                  ),
                )
                .toList(),
            selected: <CurriculumType>{_type},
            onSelectionChanged: (Set<CurriculumType> s) =>
                setState(() => _type = s.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? l.admSaving : l.admSave,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
