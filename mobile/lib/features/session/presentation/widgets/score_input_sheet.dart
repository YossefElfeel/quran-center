import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/settings/settings_repository.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../progress_engine/domain/progress_engine.dart';
import '../../domain/roster_entry.dart';
import '../../domain/tasmee_kind.dart';
import '../controllers/today_session_controller.dart';
import 'score_pad.dart';

/// شيت تسجيل درجة التسميع لطالب (/١٠) — حفظ على المقطع الحالي أو مراجعة.
class ScoreInputSheet extends ConsumerStatefulWidget {
  const ScoreInputSheet({
    required this.circleId,
    required this.entry,
    this.hasRevision = false,
    super.key,
  });

  final String circleId;
  final RosterEntry entry;
  final bool hasRevision;

  @override
  ConsumerState<ScoreInputSheet> createState() => _ScoreInputSheetState();
}

class _ScoreInputSheetState extends ConsumerState<ScoreInputSheet> {
  int? _score;
  bool _saving = false;
  TasmeeKind _kind = TasmeeKind.memorization;

  /// مفتاح المحاولة — يتعمل مرة واحدة عند فتح الشيت عشان الإعادة تكون idempotent.
  late final String _idemKey = const Uuid().v4();

  Future<void> _submit() async {
    final int? score = _score;
    if (score == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(todaySessionControllerProvider(widget.circleId).notifier)
          .recordTasmee(
            enrollmentId: widget.entry.enrollmentId,
            studentPersonId: widget.entry.studentPersonId,
            score: score,
            idempotencyKey: _idemKey,
            kind: _kind,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, AppL10n.of(context).sesTasmeeSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int threshold =
        ref.watch(appSettingsProvider).asData?.value.passThreshold ??
        ProgressEngine.defaultPassThreshold;
    final int? score = _score;
    final bool passed = score != null && score >= threshold;
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
            l.sesTasmeeTitle(widget.entry.studentName),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (widget.hasRevision) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: SegmentedButton<TasmeeKind>(
                segments: <ButtonSegment<TasmeeKind>>[
                  ButtonSegment<TasmeeKind>(
                    value: TasmeeKind.memorization,
                    label: Text(l.sesTasmeeKindMemorization),
                  ),
                  ButtonSegment<TasmeeKind>(
                    value: TasmeeKind.revision,
                    label: Text(l.sesTasmeeKindRevision),
                  ),
                ],
                selected: <TasmeeKind>{_kind},
                onSelectionChanged: (Set<TasmeeKind> s) =>
                    setState(() => _kind = s.first),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ScorePad(
            selected: _score,
            threshold: threshold,
            onSelected: (int v) => setState(() => _score = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (score != null)
            Text(
              passed ? l.sesTasmeePassed : l.sesTasmeeNeedsRetry,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: passed ? context.palette.success : context.palette.error,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: _saving ? l.sesTasmeeSaving : l.sesTasmeeSave,
            icon: Icons.check,
            isLoading: _saving,
            onPressed: (score == null || _saving) ? null : _submit,
          ),
        ],
      ),
    );
  }
}
