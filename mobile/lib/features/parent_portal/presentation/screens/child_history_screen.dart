import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../session/domain/attendance_status.dart';
import '../../../session/domain/tasmee_kind.dart';
import '../../domain/child_history.dart';
import '../controllers/child_history_controllers.dart';

/// سجلّ الطفل: تبويب التسميع + تبويب الحضور (تفصيل ما كان مجرّد ملخّص في الكارت).
class ChildHistoryScreen extends ConsumerWidget {
  const ChildHistoryScreen({
    required this.studentPersonId,
    required this.childName,
    this.initialTab = 0,
    super.key,
  });

  final String studentPersonId;
  final String childName;
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.clamp(0, 1),
      child: AppScaffold(
        title: l.ppHistoryTitle(childName),
        body: Column(
          children: <Widget>[
            TabBar(
              tabs: <Widget>[
                Tab(text: l.ppTabTasmee),
                Tab(text: l.ppTabAttendance),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _TasmeeTab(studentPersonId: studentPersonId),
                  _AttendanceTab(studentPersonId: studentPersonId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasmeeTab extends ConsumerWidget {
  const _TasmeeTab({required this.studentPersonId});

  final String studentPersonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<TasmeeHistoryEntry>> state = ref.watch(
      childTasmeeHistoryProvider(studentPersonId),
    );
    return state.when(
      loading: () => const AppListSkeleton(),
      error: (Object e, StackTrace _) => AppErrorView(
        message: l.ppHistoryLoadError,
        onRetry: () =>
            ref.invalidate(childTasmeeHistoryProvider(studentPersonId)),
      ),
      data: (List<TasmeeHistoryEntry> items) => items.isEmpty
          ? EmptyState(message: l.ppNoTasmeeYet, icon: Icons.record_voice_over)
          : AppRefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(childTasmeeHistoryProvider(studentPersonId)),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) =>
                    _TasmeeRow(entry: items[i]),
              ),
            ),
    );
  }
}

class _TasmeeRow extends StatelessWidget {
  const _TasmeeRow({required this.entry});

  final TasmeeHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final bool isRevision = entry.kind == TasmeeKind.revision;
    final Color scoreColor = entry.passed ? p.success : p.error;
    return AppListCard(
      leadingIcon: isRevision ? Icons.replay : Icons.menu_book,
      iconColor: isRevision ? p.accent : p.primary,
      title: entry.portionName.isEmpty
          ? (isRevision ? l.ppKindRevision : l.ppKindMemorization)
          : entry.portionName,
      subtitle:
          '${isRevision ? l.ppKindRevision : l.ppKindMemorization} · ${_dateLabel(entry.date)}',
      trailing: Text(
        l.ppScoreOf10(arabicNumber(entry.score)),
        style: AppTextStyles.titleMd.copyWith(
          color: scoreColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AttendanceTab extends ConsumerWidget {
  const _AttendanceTab({required this.studentPersonId});

  final String studentPersonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<AttendanceHistoryEntry>> state = ref.watch(
      childAttendanceHistoryProvider(studentPersonId),
    );
    return state.when(
      loading: () => const AppListSkeleton(),
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
          : AppRefreshIndicator(
              onRefresh: () async => ref.invalidate(
                childAttendanceHistoryProvider(studentPersonId),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) =>
                    _AttendanceRow(entry: items[i]),
              ),
            ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.entry});

  final AttendanceHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final (IconData icon, Color color) = switch (entry.status) {
      AttendanceStatus.present => (Icons.check_circle, p.success),
      AttendanceStatus.absent => (Icons.cancel, p.error),
      AttendanceStatus.absentExcused => (Icons.event_busy, p.accent),
      AttendanceStatus.late => (Icons.schedule, p.warning),
    };
    return AppListCard(
      leadingIcon: icon,
      iconColor: color,
      title: entry.status.labelAr,
      subtitle: entry.date != null ? _dateLabel(entry.date!) : l.ppNoDate,
    );
  }
}

String _dateLabel(DateTime d) =>
    '${arabicNumber(d.day)}/${arabicNumber(d.month)}/${arabicNumber(d.year)}';
