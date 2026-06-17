import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../enrollment/domain/gender.dart';
import '../../data/session_repository.dart';
import '../../domain/attendance_status.dart';
import '../../domain/roster_entry.dart';

part 'today_session_controller.g.dart';

/// "حصة النهارده" لحلقة معيّنة: تحميل الحصة المفتوحة + الروستر + الحضور،
/// وفتح/قفل الحصة وتعديل الحضور.
@riverpod
class TodaySessionController extends _$TodaySessionController {
  @override
  Future<TodaySession> build(String circleId) async {
    final SessionRepository repo = ref.watch(sessionRepositoryProvider);
    final String? sessionId = await repo.openSessionId(circleId);
    final List<Map<String, dynamic>> rosterRows =
        await repo.fetchRoster(circleId);
    final Map<String, String> att = sessionId != null
        ? await repo.fetchAttendance(sessionId)
        : const <String, String>{};

    final List<RosterEntry> roster = rosterRows.map((Map<String, dynamic> r) {
      final Map<String, dynamic> s = r['student'] as Map<String, dynamic>;
      final String enrId = r['id'] as String;
      return RosterEntry(
        enrollmentId: enrId,
        studentName: s['full_name'] as String,
        gender: Gender.fromDb(s['gender'] as String?),
        attendance: AttendanceStatus.fromDb(att[enrId] ?? 'present'),
      );
    }).toList();

    return TodaySession(sessionId: sessionId, roster: roster);
  }

  Future<void> openSession() async {
    final String? personId = await ref.read(currentPersonIdProvider.future);
    await ref.read(sessionRepositoryProvider).openSession(circleId, personId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> setAttendance(
    String enrollmentId,
    AttendanceStatus status,
  ) async {
    final TodaySession? current = state.asData?.value;
    final String? sessionId = current?.sessionId;
    if (current == null || sessionId == null) return;
    await ref.read(sessionRepositoryProvider).setAttendance(
          sessionId: sessionId,
          enrollmentId: enrollmentId,
          status: status.dbValue,
        );
    final List<RosterEntry> roster = current.roster
        .map(
          (RosterEntry e) => e.enrollmentId == enrollmentId
              ? e.copyWith(attendance: status)
              : e,
        )
        .toList();
    state = AsyncData<TodaySession>(
      TodaySession(sessionId: sessionId, roster: roster),
    );
  }

  Future<void> close() async {
    final String? sessionId = state.asData?.value.sessionId;
    if (sessionId == null) return;
    await ref.read(sessionRepositoryProvider).closeSession(sessionId);
    ref.invalidateSelf();
    await future;
  }
}
