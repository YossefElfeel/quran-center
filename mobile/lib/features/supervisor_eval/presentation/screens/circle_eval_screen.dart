import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../documents/domain/monthly_circle_report.dart';
import '../../../documents/domain/monthly_circle_report_pdf.dart';
import '../../data/supervisor_eval_repository.dart';
import '../../domain/eval_student.dart';
import '../controllers/circle_eval_controller.dart';
import '../widgets/criteria_eval_sheet.dart';
import '../widgets/eval_student_tile.dart';

/// تقييم حلقة: اختيار عشوائي + تقييم ٣×١٠ لكل طالب.
class CircleEvalScreen extends ConsumerWidget {
  const CircleEvalScreen({
    required this.circleId,
    required this.circleName,
    super.key,
  });

  final String circleId;
  final String circleName;

  void _openEval(BuildContext context, EvalStudent s) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => CriteriaEvalSheet(
        circleId: circleId,
        studentPersonId: s.studentPersonId,
        studentName: s.fullName,
      ),
    );
  }

  /// يجهّز تقرير الحلقة الشهري (للشهر الحالي) ويفتح معاينة الطباعة.
  Future<void> _printMonthlyReport(BuildContext context, WidgetRef ref) async {
    final AppL10n l = AppL10n.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final DateTime now = DateTime.now();
      final MonthlyCircleReport report = await ref
          .read(supervisorEvalRepositoryProvider)
          .fetchMonthlyCircleReport(
            circleId: circleId,
            circleName: circleName,
            month: DateTime(now.year, now.month),
          );
      final ByteData fontData = await rootBundle.load('assets/fonts/Cairo.ttf');
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat _) =>
            buildMonthlyCircleReportPdf(report: report, fontData: fontData),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.supMonthlyReportError)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<EvalStudent>> state = ref.watch(
      circleEvalControllerProvider(circleId),
    );
    return AppScaffold(
      title: circleName,
      actions: <Widget>[
        IconButton(
          tooltip: l.supPrintMonthlyReport,
          icon: const Icon(Icons.print),
          onPressed: () => _printMonthlyReport(context, ref),
        ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.supStudentsLoadError,
          onRetry: () => ref.invalidate(circleEvalControllerProvider(circleId)),
        ),
        data: (List<EvalStudent> students) {
          if (students.isEmpty) {
            return EmptyState(
              message: l.supNoStudentsInCircle,
              icon: Icons.groups_outlined,
            );
          }
          final CircleEvalController notifier = ref.read(
            circleEvalControllerProvider(circleId).notifier,
          );
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppButton(
                  label: l.supRandomPick,
                  icon: Icons.shuffle,
                  onPressed: () => notifier.randomPick(3),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  itemCount: students.length,
                  itemBuilder: (BuildContext context, int i) => EvalStudentTile(
                    key: ValueKey<String>(students[i].studentPersonId),
                    student: students[i],
                    onEvaluate: () => _openEval(context, students[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
