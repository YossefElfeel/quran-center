import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../session/presentation/widgets/score_pad.dart';
import '../../domain/eval_criterion.dart';
import '../controllers/circle_eval_controller.dart';

/// شيت تقييم المشرف لطالب: المعايير الـ٣ ×١٠ (حفظ/تلاوة/قراءة من المصحف).
class CriteriaEvalSheet extends ConsumerStatefulWidget {
  const CriteriaEvalSheet({
    required this.circleId,
    required this.studentPersonId,
    required this.studentName,
    super.key,
  });

  final String circleId;
  final String studentPersonId;
  final String studentName;

  @override
  ConsumerState<CriteriaEvalSheet> createState() => _CriteriaEvalSheetState();
}

class _CriteriaEvalSheetState extends ConsumerState<CriteriaEvalSheet> {
  final Map<EvalCriterion, int> _scores = <EvalCriterion, int>{};
  bool _saving = false;

  bool get _complete => _scores.length == EvalCriterion.values.length;

  Future<void> _save() async {
    if (!_complete) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(circleEvalControllerProvider(widget.circleId).notifier)
          .recordEval(
            widget.studentPersonId,
            Map<EvalCriterion, int>.of(_scores),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مش قادرين نحفظ التقييم — جرّب تاني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'تقييم: ${widget.studentName}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            for (final EvalCriterion c in EvalCriterion.values) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Text(
                c.labelAr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              // عتبة ٧ للتلوين فقط (مفيش نجاح/رسوب في تقييم المشرف).
              ScorePad(
                selected: _scores[c],
                threshold: 7,
                onSelected: (int v) => setState(() => _scores[c] = v),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _saving ? 'بنحفظ…' : 'حفظ التقييم',
              icon: Icons.check,
              onPressed: (_complete && !_saving) ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
