import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../enrollment/domain/gender.dart';
import '../../../progress_engine/domain/ledger_state.dart';
import '../../../progress_engine/domain/progress_engine.dart';
import '../../data/session_repository.dart';
import '../../domain/attendance_status.dart';
import '../../domain/portion.dart';
import '../../domain/roster_entry.dart';

part 'today_session_controller.g.dart';

/// "حصة النهارده" لحلقة: تحميل الحصة المفتوحة + المقطع الحالي + الروستر
/// + الحضور + الدَيْن، وفتح/قفل الحصة وتعديل الحضور وتسجيل التسميع.
@riverpod
class TodaySessionController extends _$TodaySessionController {
  @override
  Future<TodaySession> build(String circleId) async {
    final SessionRepository repo = ref.watch(sessionRepositoryProvider);
    final String? sessionId = await repo.openSessionId(circleId);
    final List<Map<String, dynamic>> rosterRows = await repo.fetchRoster(
      circleId,
    );
    final Portion? portion = await repo.currentPortion(circleId);
    final Map<String, String> att = sessionId != null
        ? await repo.fetchAttendance(sessionId)
        : const <String, String>{};

    final List<String> studentIds = <String>[
      for (final Map<String, dynamic> r in rosterRows)
        r['student_person_id'] as String,
    ];
    final Map<String, LedgerState> ledger = portion != null
        ? await repo.fetchLedger(portion.id, studentIds)
        : const <String, LedgerState>{};

    final List<RosterEntry> roster = rosterRows.map((Map<String, dynamic> r) {
      final Map<String, dynamic> s = r['student'] as Map<String, dynamic>;
      final String enrId = r['id'] as String;
      final String pid = r['student_person_id'] as String;
      return RosterEntry(
        enrollmentId: enrId,
        studentPersonId: pid,
        studentName: s['full_name'] as String,
        gender: Gender.fromDb(s['gender'] as String?),
        attendance: AttendanceStatus.fromDb(att[enrId] ?? 'present'),
        ledgerState: ledger[pid],
      );
    }).toList();

    return TodaySession(
      sessionId: sessionId,
      roster: roster,
      currentPortion: portion,
    );
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
    await ref
        .read(sessionRepositoryProvider)
        .setAttendance(
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
    state = AsyncData<TodaySession>(current.copyWith(roster: roster));
  }

  /// تحديد مقطع الحفظ الحالي للحلقة (ينشئ مقطع + يفتح دورة).
  Future<void> setPortion({
    required String name,
    required int surahStart,
    required int ayahStart,
    required int surahEnd,
    required int ayahEnd,
  }) async {
    await ref
        .read(sessionRepositoryProvider)
        .setCurrentPortion(
          circleId: circleId,
          name: name,
          surahStart: surahStart,
          ayahStart: ayahStart,
          surahEnd: surahEnd,
          ayahEnd: ayahEnd,
        );
    ref.invalidateSelf();
    await future;
  }

  /// تسجيل تسميع لطالب على المقطع الحالي (درجة /١٠).
  Future<void> recordTasmee({
    required String enrollmentId,
    required String studentPersonId,
    required int score,
  }) async {
    final TodaySession? current = state.asData?.value;
    final Portion? portion = current?.currentPortion;
    if (current == null || portion == null) return;
    final bool passed = ProgressEngine.isPassing(
      score: score,
      threshold: ProgressEngine.defaultPassThreshold,
    );
    final String? teacherId = await ref.read(currentPersonIdProvider.future);
    final LedgerState next = await ref
        .read(sessionRepositoryProvider)
        .recordTasmee(
          enrollmentId: enrollmentId,
          studentPersonId: studentPersonId,
          portionId: portion.id,
          score: score,
          passed: passed,
          idempotencyKey: const Uuid().v4(),
          teacherId: teacherId,
          sessionId: current.sessionId,
        );
    final List<RosterEntry> roster = current.roster
        .map(
          (RosterEntry e) => e.studentPersonId == studentPersonId
              ? e.copyWith(ledgerState: next)
              : e,
        )
        .toList();
    state = AsyncData<TodaySession>(current.copyWith(roster: roster));
  }

  Future<void> close() async {
    final String? sessionId = state.asData?.value.sessionId;
    if (sessionId == null) return;
    await ref.read(sessionRepositoryProvider).closeSession(sessionId);
    ref.invalidateSelf();
    await future;
  }
}
