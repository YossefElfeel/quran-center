import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/monthly_plan.dart';
import '../controllers/circle_monthly_plan_controller.dart';

/// محرّر خطة الشهر للحلقة (المعلّم) — منهج الشهر + نظام التدريس + المقاطع.
class MonthlyPlanEditorScreen extends ConsumerStatefulWidget {
  const MonthlyPlanEditorScreen({
    required this.circleId,
    required this.circleName,
    super.key,
  });

  final String circleId;
  final String circleName;

  @override
  ConsumerState<MonthlyPlanEditorScreen> createState() =>
      _MonthlyPlanEditorScreenState();
}

class _MonthlyPlanEditorScreenState
    extends ConsumerState<MonthlyPlanEditorScreen> {
  final TextEditingController _curriculum = TextEditingController();
  final TextEditingController _method = TextEditingController();
  final TextEditingController _portions = TextEditingController();
  bool _prefilled = false;
  bool _saving = false;

  @override
  void dispose() {
    _curriculum.dispose();
    _method.dispose();
    _portions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final AppL10n l = AppL10n.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(circleMonthlyPlanControllerProvider(widget.circleId).notifier)
          .save(
            curriculumPlan: _curriculum.text.trim(),
            teachingMethod: _method.text.trim(),
            portionsRef: _portions.text.trim(),
          );
      if (!mounted) return;
      AppSnackbar.success(context, l.monPlanSaved);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, l.monPlanSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    ref.listen<AsyncValue<MonthlyPlan?>>(
      circleMonthlyPlanControllerProvider(widget.circleId),
      (AsyncValue<MonthlyPlan?>? prev, AsyncValue<MonthlyPlan?> next) {
        final MonthlyPlan? p = next.asData?.value;
        if (p != null && !_prefilled) {
          _curriculum.text = p.curriculumPlan ?? '';
          _method.text = p.teachingMethod ?? '';
          _portions.text = p.portionsRef ?? '';
          _prefilled = true;
        }
      },
    );
    final AsyncValue<MonthlyPlan?> state = ref.watch(
      circleMonthlyPlanControllerProvider(widget.circleId),
    );
    return AppScaffold(
      title: l.monPlanEditorTitle(widget.circleName),
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.monLoadPlanFailed,
          onRetry: () => ref.invalidate(
            circleMonthlyPlanControllerProvider(widget.circleId),
          ),
        ),
        data: (MonthlyPlan? _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            Text(
              l.monPlanVisibleToParents,
              style: TextStyle(color: context.palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _curriculum,
              minLines: 2,
              maxLines: 4,
              label: l.monCurriculumLabel,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _method,
              minLines: 1,
              maxLines: 3,
              label: l.monTeachingMethodLabel,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _portions,
              minLines: 1,
              maxLines: 2,
              label: l.monPortionsLabel,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _saving ? l.monSaving : l.monSavePlan,
              icon: Icons.save,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
