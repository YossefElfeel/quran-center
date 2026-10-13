import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_icons.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_hero.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_segmented_control.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../documents/domain/progress_card_pdf.dart';
import '../../../feedback/presentation/widgets/rate_teacher_sheet.dart';
import '../../../media/presentation/widgets/child_media_section.dart';
import '../../domain/child_card.dart';
import '../../domain/child_history.dart';
import '../controllers/child_card_controller.dart';
import '../controllers/child_history_controllers.dart';
import '../widgets/child_certificates_section.dart';
import '../widgets/child_comments_section.dart';
import '../widgets/child_consent_section.dart';
import '../widgets/child_journey_section.dart';
import '../widgets/child_monthly_plan_section.dart';
import 'child_history_screen.dart';

/// كارت متابعة الطفل: الحلقة + آخر تسميع + ملخّص الحضور.
class ChildCardScreen extends ConsumerStatefulWidget {
  const ChildCardScreen({
    required this.studentPersonId,
    required this.childName,
    super.key,
  });

  final String studentPersonId;
  final String childName;
  @override
  ConsumerState<ChildCardScreen> createState() => _ChildCardScreenState();
}

class _ChildCardScreenState extends ConsumerState<ChildCardScreen> {
  int _tab = 0;
  String get studentPersonId => widget.studentPersonId;
  String get childName => widget.childName;

  Future<void> _printProgressCard(BuildContext context, WidgetRef ref) async {
    final ChildCard? card = ref
        .read(childCardProvider(studentPersonId))
        .asData
        ?.value;
    if (card == null) return;
    final ByteData fontData = await rootBundle.load('assets/fonts/Cairo.ttf');
    final LatestTasmee? lt = card.latestTasmee;
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat _) => buildProgressCardPdf(
        studentName: childName,
        circleName: card.circleName ?? 'الحلقة',
        present: card.present,
        absent: card.absent,
        excused: card.excused,
        late: card.late,
        latestScore: lt != null ? '${arabicNumber(lt.score)}/١٠' : null,
        fontData: fontData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<ChildCard> state = ref.watch(
      childCardProvider(studentPersonId),
    );
    return AppScaffold(
      title: childName,
      actions: <Widget>[
        IconButton(
          tooltip: l.ppPrintProgressCard,
          icon: const Icon(Icons.print),
          onPressed: () => _printProgressCard(context, ref),
        ),
        IconButton(
          tooltip: l.ppRateTeacher,
          icon: const Icon(Icons.star_rate),
          onPressed: () => showAppModalSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext _) =>
                RateTeacherSheet(studentPersonId: studentPersonId),
          ),
        ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.ppCardLoadError,
          onRetry: () => ref.invalidate(childCardProvider(studentPersonId)),
        ),
        data: (ChildCard card) {
          final LatestTasmee? lt = card.latestTasmee;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              Center(
                child: Column(
                  children: <Widget>[
                    AppHero(
                      tag: 'child-avatar-$studentPersonId',
                      child: AppAvatar(name: childName, radius: 40),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      childName,
                      style: AppTextStyles.titleLg.copyWith(
                        color: context.palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // الملخّص مرّة واحدة فوق التبويبات (مش جوّه كل تبويب).
              _InfoCard(
                icon: Icons.groups,
                title: l.ppCircle,
                value: card.circleName ?? l.ppNotInCircle,
              ),
              if (card.currentPortion != null)
                _InfoCard(
                  icon: Icons.menu_book,
                  title: 'المقطع الحالي',
                  value: card.currentPortion!,
                ),
              if (lt != null)
                _InfoCard(
                  icon: Icons.record_voice_over,
                  title: l.ppLastTasmee,
                  value: l.ppLastTasmeeValue(
                    lt.portionName,
                    arabicNumber(lt.score),
                    lt.passed ? l.ppPassed : l.ppNeedsRetry,
                  ),
                  valueColor: lt.passed
                      ? context.palette.success
                      : context.palette.error,
                  hint: l.ppViewFullHistory,
                  onTap: () => context.push(
                    Routes.parentChildHistory(studentPersonId, childName),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: AppSegmentedControl<int>(
                  segments: const [
                    (value: 0, label: 'التقدّم'),
                    (value: 1, label: 'الحضور'),
                    (value: 2, label: 'الشهادات'),
                    (value: 3, label: 'الوسائط والموافقة'),
                    (value: 4, label: 'الملاحظات'),
                  ],
                  selected: _tab,
                  onChanged: (int v) => setState(() => _tab = v),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_tab == 1) ...<Widget>[
                _AttendanceCard(card: card),
                _AttendanceHistoryList(
                  studentPersonId: studentPersonId,
                  onViewAll: () => context.push(
                    Routes.parentChildHistory(
                      studentPersonId,
                      childName,
                      tab: 1,
                    ),
                  ),
                ),
              ],
              if (_tab == 2)
                ChildCertificatesSection(
                  studentPersonId: studentPersonId,
                  childName: childName,
                ),
              if (_tab == 0)
                ChildMonthlyPlanSection(studentPersonId: studentPersonId),
              if (_tab == 0)
                ChildJourneySection(studentPersonId: studentPersonId),
              if (_tab == 3 && card.isGirl)
                ChildConsentSection(studentPersonId: studentPersonId),
              if (_tab == 3)
                ChildMediaSection(studentPersonId: studentPersonId),
              if (_tab == 4)
                ChildCommentsSection(studentPersonId: studentPersonId),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
    this.hint,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final String? hint = this.hint;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            Icon(icon, color: p.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyles.labelSm.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.titleMd.copyWith(
                      color: valueColor ?? p.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              if (hint != null)
                Text(
                  hint,
                  style: AppTextStyles.labelSm.copyWith(color: p.primary),
                ),
              Icon(AppIcons.drillIn, color: p.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.card});

  final ChildCard card;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${l.ppAttendance} — الشهر الحالي',
                    style: AppTextStyles.labelSm.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                _Pill(
                  label: l.ppPresent,
                  count: card.present,
                  color: p.success,
                ),
                _Pill(label: l.ppAbsent, count: card.absent, color: p.error),
                _Pill(label: l.ppExcused, count: card.excused, color: p.accent),
                _Pill(
                  label: l.ppLate,
                  count: card.late,
                  color: p.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// آخر تسجيلات الحضور (من نفس بيانات شاشة السجل) + رابط للسجل الكامل.
class _AttendanceHistoryList extends ConsumerWidget {
  const _AttendanceHistoryList({
    required this.studentPersonId,
    required this.onViewAll,
  });

  final String studentPersonId;
  final VoidCallback onViewAll;

  static const int _maxRows = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<AttendanceHistoryEntry>> state = ref.watch(
      childAttendanceHistoryProvider(studentPersonId),
    );
    return state.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: LinearProgressIndicator(),
      ),
      error: (Object e, StackTrace _) => AppErrorView(
        message: l.ppHistoryLoadError,
        onRetry: () =>
            ref.invalidate(childAttendanceHistoryProvider(studentPersonId)),
      ),
      data: (List<AttendanceHistoryEntry> items) => items.isEmpty
          ? EmptyState(
              message: l.ppNoAttendanceYet,
              icon: Icons.event_available,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final AttendanceHistoryEntry e in items.take(_maxRows))
                  AttendanceHistoryRow(entry: e),
                if (items.length > _maxRows)
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(l.ppViewAttendanceLog),
                  ),
              ],
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.badgeTint),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        l.ppPillLabel(label, arabicNumber(count)),
        style: AppTextStyles.labelLg.copyWith(color: color),
      ),
    );
  }
}
