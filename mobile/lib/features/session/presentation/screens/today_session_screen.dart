import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/settings/settings_repository.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/presentation/domain_labels.dart';
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
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../documents/domain/attendance_sheet_pdf.dart';
import '../../../progress_engine/domain/ledger_state.dart';
import '../../domain/attendance_status.dart';
import '../../domain/roster_entry.dart';
import '../../domain/session_write_block.dart';
import '../controllers/today_session_controller.dart';
import '../session_write_block_label.dart';
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

class _SessionBody extends ConsumerStatefulWidget {
  const _SessionBody({required this.circleId, required this.session});

  final String circleId;
  final TodaySession session;

  @override
  ConsumerState<_SessionBody> createState() => _SessionBodyState();
}

class _SessionBodyState extends ConsumerState<_SessionBody> {
  String get circleId => widget.circleId;
  TodaySession get session => widget.session;
  final Set<String> _requestingExcuses = <String>{};

  void _openSetPortion(BuildContext context, {bool advanceMode = false}) {
    showAppModalSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) =>
          SetPortionSheet(circleId: circleId, advanceMode: advanceMode),
    );
  }

  void _openTasmee(BuildContext context, RosterEntry entry, bool hasRevision) {
    showAppModalSheet<void>(
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
    showAppModalSheet<void>(
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
    showAppModalSheet<void>(
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
    if (_requestingExcuses.contains(enrollmentId)) return;
    setState(() => _requestingExcuses.add(enrollmentId));
    try {
      // The sheet owns its text controller, so it is disposed only after the
      // closing animation finishes (not while the sheet is still building).
      final String? text = await showAppModalSheet<String>(
        context: context,
        title: 'طلب عذر',
        builder: (BuildContext _) => const _ExcuseReasonSheet(),
      );
      if (text == null) return;
      try {
        await notifier.requestExcuse(
          enrollmentId,
          reason: text.isEmpty ? null : text,
        );
      } catch (_) {
        if (context.mounted) {
          AppSnackbar.error(context, 'تعذّر إرسال طلب العذر');
        }
        return;
      }
      if (context.mounted) {
        AppSnackbar.success(context, AppL10n.of(context).sesExcuseRequestSent);
      }
    } finally {
      if (mounted) setState(() => _requestingExcuses.remove(enrollmentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    if (session.roster.isEmpty) {
      return EmptyState(
        message: l.sesNoStudentsInCircle,
        icon: Icons.groups_outlined,
        action: TextButton(
          onPressed: () async {
            final roles =
                ref.read(currentRolesProvider).asData?.value ?? <String>[];
            if (roles.contains('admin') || roles.contains('super_admin')) {
              await context.push<void>('/admin/circles/$circleId/students');
              return;
            }
            try {
              final settings = await ref.read(appSettingsProvider.future);
              if (settings.centerPhone.isNotEmpty) {
                await launchUrl(Uri(scheme: 'tel', path: settings.centerPhone));
              } else if (context.mounted) {
                AppSnackbar.info(
                  context,
                  'رقم الإدارة مش مضاف — كلّم المشرف لربط الطلبة',
                );
              }
            } catch (_) {
              if (context.mounted) {
                AppSnackbar.error(context, 'تعذّر تحميل رقم الإدارة');
              }
            }
          },
          child: Text(
            (ref.watch(currentRolesProvider).asData?.value ?? <String>[]).any(
                  (r) => r == 'admin' || r == 'super_admin',
                )
                ? 'ضيف طلاب'
                : 'كلّم الإدارة',
          ),
        ),
      );
    }
    final TodaySessionController notifier = ref.read(
      todaySessionControllerProvider(circleId).notifier,
    );

    if (!session.isOpen) {
      return _ClosedView(onOpen: notifier.openSession, session: session);
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
                excuseRequested: e.excuseRequested,
                canRecordTasmee: session.hasPortion,
                onAttendanceChanged: (AttendanceStatus s) async {
                  try {
                    await notifier.setAttendance(e.enrollmentId, s);
                  } catch (_) {
                    if (context.mounted) {
                      AppSnackbar.error(
                        context,
                        'تعذّر حفظ الحضور — جرّب تاني',
                      );
                    }
                  }
                },
                onTasmee: () => _openTasmee(context, e, hasRevision),
                onNote: () => _openNote(context, e),
                onRequestExcuse:
                    e.attendance == AttendanceStatus.absent &&
                        !e.excuseRequested &&
                        !_requestingExcuses.contains(e.enrollmentId)
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

class _ClosedView extends StatefulWidget {
  const _ClosedView({required this.onOpen, required this.session});
  final Future<void> Function() onOpen;
  final TodaySession session;
  @override
  State<_ClosedView> createState() => _ClosedViewState();
}

class _ClosedViewState extends State<_ClosedView> {
  bool _busy = false;
  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onOpen();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          e is SessionWritesBlockedException
              ? e.reason.label(AppL10n.of(context))
              : 'تعذّر فتح الحصة — راجع الاتصال وجرّب تاني',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
            widget.session.closedToday
                ? '✓ حصة النهارده اتقفلت — ${arabicNumber(widget.session.presentCount)} حضور، ${arabicNumber(widget.session.tasmeeCount)} تسميع، ${arabicNumber(widget.session.absentCount)} غياب'
                : l.sesSessionStillClosed,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLg.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.session.closedToday)
            AppButton(
              label: 'شوف التفاصيل',
              onPressed: () => showAppModalSheet<void>(
                context: context,
                title: 'تفاصيل الحصة',
                builder: (_) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final entry in widget.session.roster)
                      ListTile(
                        title: Text(entry.studentName),
                        subtitle: Text(
                          entry.attendanceRecorded
                              ? entry.attendance.label(AppL10n.of(context))
                              : 'حضور غير مسجّل',
                        ),
                        trailing: Text(
                          entry.tasmeeRecorded ? '✓ تسميع' : 'بدون تسميع',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          AppButton(
            label: widget.session.closedToday
                ? 'حصة إضافية'
                : l.sesOpenTodaySession,
            variant: widget.session.closedToday
                ? AppButtonVariant.text
                : AppButtonVariant.primary,
            isLoading: _busy,
            icon: Icons.play_arrow,
            onPressed: _open,
          ),
        ],
      ),
    );
  }
}

/// شيت سبب طلب العذر — بيملك الـ controller بتاعه عشان يتشال مع الشيت نفسه.
class _ExcuseReasonSheet extends StatefulWidget {
  const _ExcuseReasonSheet();

  @override
  State<_ExcuseReasonSheet> createState() => _ExcuseReasonSheetState();
}

class _ExcuseReasonSheetState extends State<_ExcuseReasonSheet> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      AppTextField(controller: _reason, label: 'السبب (اختياري)', maxLines: 3),
      const SizedBox(height: AppSpacing.md),
      AppButton(
        label: 'إرسال الطلب',
        onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
      ),
    ],
  );
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
