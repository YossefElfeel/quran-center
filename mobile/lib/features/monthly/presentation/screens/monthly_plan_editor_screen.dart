import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اتسجّلت خطة الشهر')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مش قادرين نحفظ — جرّب تاني')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      title: 'خطة الشهر — ${widget.circleName}',
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الخطة',
          onRetry: () => ref.invalidate(
            circleMonthlyPlanControllerProvider(widget.circleId),
          ),
        ),
        data: (MonthlyPlan? _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            const Text(
              'الخطة بتظهر لأولياء أمور طلبة الحلقة',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _curriculum,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'منهج الشهر',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _method,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'نظام التدريس',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _portions,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'المقاطع المطلوبة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _saving ? 'بنحفظ…' : 'حفظ الخطة',
              icon: Icons.save,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
