import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/attendance_status.dart';
import '../../domain/roster_entry.dart';
import '../controllers/today_session_controller.dart';
import '../widgets/advance_confirmation_dialog.dart';
import '../widgets/advance_suggestion_banner.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TodaySession> state = ref.watch(
      todaySessionControllerProvider(circleId),
    );
    return AppScaffold(
      title: circleName,
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الحصة',
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

  void _openClose(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => CloseSessionSheet(circleId: circleId),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (session.roster.isEmpty) {
      return const EmptyState(
        message: 'مفيش طلبة في الحلقة',
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
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppButton(
            label: 'اقفل الحصة',
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.event_available, size: 64, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'الحصة لسه مقفولة',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'افتح حصة النهارده',
            icon: Icons.play_arrow,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
