import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../documents/domain/attendance_sheet_pdf.dart';
import '../../../progress_engine/domain/ledger_state.dart';
import '../../domain/attendance_status.dart';
import '../../domain/roster_entry.dart';
import '../controllers/today_session_controller.dart';
import '../widgets/advance_confirmation_dialog.dart';
import '../widgets/advance_suggestion_banner.dart';
import '../widgets/behavioral_note_sheet.dart';
import '../widgets/close_session_sheet.dart';
import '../widgets/current_portion_card.dart';
import '../widgets/debt_strip.dart';
import '../widgets/required_revision_banner.dart';
import '../widgets/score_input_sheet.dart';
import '../widgets/set_portion_sheet.dart';
import '../widgets/student_tile.dart';

/// حصة النهارده — فتح/مقطع/حضور/تسميع/مراجعة/اقتراح انتقال/قفل بخطة.
class TodaySessionScreen extends ConsumerWidget {
  const TodaySessionScreen({
    required this.circleId,
    required this.circleName,
    super.key,
  });

  final String circleId;
  final String circleName;

  Future<void> _printAttendance(BuildContext context, WidgetRef ref) async {
    final TodaySession? s = ref
        .read(todaySessionControllerProvider(circleId))
        .asData
        ?.value;
    if (s == null || s.roster.isEmpty) return;
    final ByteData fontData = await rootBundle.load('assets/fonts/Cairo.ttf');
    final DateTime now = DateTime.now();
    final String date =
        '${arabicNumber(now.day)}/${arabicNumber(now.month)}/'
        '${arabicNumber(now.year)}';
    final List<String> names = s.roster
        .map((RosterEntry e) => e.studentName)
        .toList();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat _) => buildAttendanceSheetPdf(
        circleName: circleName,
        dateLabel: date,
        studentNames: names,
        fontData: fontData,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<TodaySession> state = ref.watch(
      todaySessionControllerProvider(circleId),
    );
    return AppScaffold(
      title: circleName,
      actions: <Widget>[
        IconButton(
          tooltip: l.sesAttendanceSheetPdf,
          icon: const Icon(Icons.print),
          onPressed: () => _printAttendance(context, ref),
        ),
      ],
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.sesSessionLoadError,
          onRetry: () =>
              ref.invalidate(todaySessionControllerProvider(circleId)),
        ),
        data: (TodaySession session) =>
            _SessionBody(circleId: circleId, session: session),
      ),
    );
  }
}

class _SessionBody extends ConsumerWidget {
  const _SessionBody({required this.circleId, required this.session});

  final String circleId;
  final TodaySession session;

  void _openSetPortion(BuildContext context, {bool advanceMode = false}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) =>
          SetPortionSheet(circleId: circleId, advanceMode: advanceMode),
    );
  }

  void _openTasmee(BuildContext context, RosterEntry entry, bool hasRevision) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => ScoreInputSheet(
        circleId: circleId,
        entry: entry,
        hasRevision: hasRevision,
      ),
    );
  }

  void _openNote(BuildContext context, RosterEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => BehavioralNoteSheet(
        circleId: circleId,
        studentPersonId: entry.studentPersonId,
        studentName: entry.studentName,
      ),
    );
  }

  void _openClose(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => CloseSessionSheet(circleId: circleId),
    );
  }

  /// قائمة المدينين: مين لسه ماعدّاش المقطع الحالي (متعثّر أو لسه ماتسمّعش).
  void _openDebtors(BuildContext context) {
    final List<RosterEntry> debtors =
        session.roster
            .where((RosterEntry e) => e.ledgerState != LedgerState.passed)
            .toList()
          ..sort((RosterEntry a, RosterEntry b) {
            int rank(LedgerState? s) => s == LedgerState.failedRetry ? 0 : 1;
            return rank(a.ledgerState).compareTo(rank(b.ledgerState));
          });
    showAppModalSheet<void>(
      context: context,
      title: AppL10n.of(context).sesDebtorsTitle,
      builder: (BuildContext context) {
        final AppL10n l = AppL10n.of(context);
        if (debtors.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l.sesNoDebtors,
              style: AppTextStyles.bodyLg.copyWith(
                color: context.palette.success,
              ),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final RosterEntry e in debtors) _DebtorRow(entry: e),
          ],
        );
      },
    );
  }

  Future<void> _confirmAdvance(BuildContext context) async {
    final bool? ok = await showAdvanceConfirmationDialog(
      context,
      passedCount: session.passedCount,
      activeAtOpen: session.activeAtOpen,
    );
    if (ok == true && context.mounted) {
      _openSetPortion(context, advanceMode: true);
    }
  }

  Future<void> _requestExcuse(
    BuildContext context,
    TodaySessionController notifier,
    String enrollmentId,
  ) async {
    await notifier.requestExcuse(enrollmentId);
    if (context.mounted) {
      AppSnackbar.success(context, AppL10n.of(context).sesExcuseRequestSent);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    if (session.roster.isEmpty) {
      return EmptyState(
        message: l.sesNoStudentsInCircle,
        icon: Icons.groups_outlined,
      );
    }
    final TodaySessionController notifier = ref.read(
      todaySessionControllerProvider(circleId).notifier,
    );

    if (!session.isOpen) {
      return _ClosedView(onOpen: notifier.openSession);
    }

    final bool hasRevision = session.requiredRevision != null;
    return Column(
      children: <Widget>[
        CurrentPortionCard(
          portion: session.currentPortion,
          onSetPortion: () => _openSetPortion(context),
        ),
        if (hasRevision)
          RequiredRevisionBanner(revision: session.requiredRevision!),
        if (session.hasPortion)
          DebtStrip(
            passedCount: session.passedCount,
            debtCount: session.debtCount,
            total: session.roster.length,
            onTap: () => _openDebtors(context),
          ),
        if (session.shouldAdvance)
          AdvanceSuggestionBanner(
            passedCount: session.passedCount,
            activeAtOpen: session.activeAtOpen,
            onAdvance: () => _confirmAdvance(context),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            itemCount: session.roster.length,
            itemBuilder: (BuildContext context, int i) {
              final RosterEntry e = session.roster[i];
              return StudentTile(
                key: ValueKey<String>(e.enrollmentId),
                entry: e,
                canRecordTasmee: session.hasPortion,
                onAttendanceChanged: (AttendanceStatus s) =>
                    notifier.setAttendance(e.enrollmentId, s),
                onTasmee: () => _openTasmee(context, e, hasRevision),
                onNote: () => _openNote(context, e),
                onRequestExcuse: e.attendance == AttendanceStatus.absent
                    ? () => _requestExcuse(context, notifier, e.enrollmentId)
                    : null,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppButton(
            label: l.sesCloseSession,
            icon: Icons.check_circle,
            onPressed: () => _openClose(context),
          ),
        ),
      ],
    );
  }
}

class _ClosedView extends StatelessWidget {
  const _ClosedView({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.event_available, size: 64, color: p.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            l.sesSessionStillClosed,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLg.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l.sesOpenTodaySession,
            icon: Icons.play_arrow,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

/// صف مدين في قائمة الدَيْن: اسم الطالب + حالته (متعثّر / لسه ماتسمّعش).
class _DebtorRow extends StatelessWidget {
  const _DebtorRow({required this.entry});

  final RosterEntry entry;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final bool failed = entry.ledgerState == LedgerState.failedRetry;
    return AppListCard(
      leadingIcon: failed ? Icons.warning_amber : Icons.hourglass_empty,
      iconColor: failed ? p.error : p.textSecondary,
      title: entry.studentName,
      trailing: AppStatusBadge(
        label: failed ? l.sesDebtorFailed : l.sesDebtorPending,
        kind: failed ? AppStatusKind.error : AppStatusKind.neutral,
      ),
    );
  }
}
