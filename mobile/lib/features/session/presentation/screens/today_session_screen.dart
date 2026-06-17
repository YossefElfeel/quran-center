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
import '../widgets/attendance_tile.dart';

/// حصة النهارده — فتح الحصة + الحضور + القفل. (التسميع في الدفعة الجاية.)
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
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.event_available,
              size: 64,
              color: AppColors.primary,
            ),
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
              onPressed: () => notifier.openSession(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: session.roster.length,
            itemBuilder: (BuildContext context, int i) {
              final RosterEntry e = session.roster[i];
              return AttendanceTile(
                entry: e,
                onChanged: (AttendanceStatus s) =>
                    notifier.setAttendance(e.enrollmentId, s),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppButton(
            label: 'اقفل الحصة',
            icon: Icons.check_circle,
            onPressed: () => notifier.close(),
          ),
        ),
      ],
    );
  }
}
