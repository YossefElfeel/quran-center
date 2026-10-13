import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/presentation/domain_labels.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../session/presentation/widgets/score_pad.dart';
import '../../domain/eval_criterion.dart';
import '../controllers/circle_eval_controller.dart';

/// شيت تقييم المشرف لطالب: المعايير الـ٣ ×١٠ (حفظ/تلاوة/قراءة من المصحف).
class CriteriaEvalSheet extends ConsumerStatefulWidget {
  const CriteriaEvalSheet({
    required this.circleId,
    required this.studentPersonId,
    required this.studentName,
    this.initialScores = const <EvalCriterion, int>{},
    super.key,
  });

  final String circleId;
  final String studentPersonId;
  final String studentName;
  final Map<EvalCriterion, int> initialScores;

  @override
  ConsumerState<CriteriaEvalSheet> createState() => _CriteriaEvalSheetState();
}

class _CriteriaEvalSheetState extends ConsumerState<CriteriaEvalSheet> {
  final Map<EvalCriterion, int> _scores = <EvalCriterion, int>{};
  bool _saving = false;

  bool get _complete => _scores.length == EvalCriterion.values.length;

  @override
  void initState() {
    super.initState();
    _scores.addAll(widget.initialScores);
  }

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
      if (mounted) {
        AppSnackbar.success(context, AppL10n.of(context).supEvalSaved);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, AppL10n.of(context).supSaveEvalError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l.supEvalStudentTitle(widget.studentName),
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSm,
            ),
            for (final EvalCriterion c in EvalCriterion.values) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Text(
                c.label(AppL10n.of(context)),
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
              label: _saving ? l.supSaving : l.supSaveEval,
              icon: Icons.check,
              onPressed: (_complete && !_saving) ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
