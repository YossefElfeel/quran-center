import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/db/local_db.dart';
import '../../../../core/network/network_status.dart';
import '../../../../core/settings/settings_repository.dart';
import '../../../../core/sync/outbox_op.dart';
import '../../../enrollment/domain/gender.dart';
import '../../../excuse/data/excuse_repository.dart';
import '../../../progress_engine/domain/ledger_state.dart';
import '../../../progress_engine/domain/progress_engine.dart';
import '../../data/current_cycle.dart';
import '../../data/session_cache.dart';
import '../../data/session_repository.dart';
import '../../data/session_sync.dart';
import '../../domain/attendance_status.dart';
import '../../domain/portion.dart';
import '../../domain/roster_entry.dart';
import '../../domain/tasmee_kind.dart';

part 'today_session_controller.g.dart';

/// "حصة النهارده" لحلقة: تحميل الحصة + المقطع الحالي + المقام المجمّد
/// + المراجعة المطلوبة + الروستر + الدَيْن، مع فتح/قفل/حضور/تسميع/انتقال.
@riverpod
class TodaySessionController extends _$TodaySessionController {
  @override
  Future<TodaySession> build(String circleId) async {
    final LocalDb db = ref.read(localDbProvider);
    final String? cached = await db.readCachedSession(circleId);
    if (cached != null && await db.hasUnsyncedSession(circleId)) {
      return decodeTodaySession(cached, preserveSession: true);
    }
    try {
      final TodaySession session = await _loadOnline(circleId);
      // كاش أفضل-جهد: مينفعش يكسر تحميل ناجح لو الكتابة المحلية فشلت.
      try {
        await db.cacheSession(circleId, encodeTodaySession(session));
      } catch (_) {}
      return session;
    } catch (e) {
      if (!isOfflineError(e)) rethrow;
      // أوفلاين → افتح من آخر كاش (لو موجود) عشان المعلّم يكمّل تسجيل في الطابور.
      if (cached == null) rethrow;
      return decodeTodaySession(cached);
    }
  }

  Future<TodaySession> _loadOnline(String circleId) async {
    final SessionRepository repo = ref.watch(sessionRepositoryProvider);
    final Map<String, dynamic>? today = await repo.todaySessionStatus(circleId);
    final String? sessionId = today?['id'] as String?;
    final List<Map<String, dynamic>> rosterRows = await repo.fetchRoster(
      circleId,
    );
    final CurrentCycle? cycle = await repo.currentCycle(circleId);
    final Portion? portion = cycle?.portion;
    final Map<String, String> att = sessionId != null
        ? await repo.fetchAttendance(sessionId)
        : const <String, String>{};
    final Portion? requiredRevision = sessionId != null
        ? await repo.fetchRequiredRevision(circleId)
        : null;

    final List<String> studentIds = <String>[
      for (final Map<String, dynamic> r in rosterRows)
        r['student_person_id'] as String,
    ];
    final Map<String, LedgerState> ledger = portion != null
        ? await repo.fetchLedger(portion.id, studentIds)
        : const <String, LedgerState>{};

    final Set<String> graded = sessionId == null
        ? <String>{}
        : await repo.fetchGradedEnrollments(sessionId);
    final Set<String> requestedExcuses = sessionId == null
        ? <String>{}
        : await repo.fetchRequestedExcuses(sessionId);
    final List<RosterEntry> roster = rosterRows.map((Map<String, dynamic> r) {
      // الـ embed ممكن يرجّع null لو RLS منعت قراءة person الطالب — منكسرش
      // التحميل، نعرض بديل بدل ما نرمي TypeError.
      final Map<String, dynamic>? s = r['student'] as Map<String, dynamic>?;
      final String enrId = r['id'] as String;
      final String pid = r['student_person_id'] as String;
      return RosterEntry(
        enrollmentId: enrId,
        studentPersonId: pid,
        studentName: (s?['full_name'] as String?) ?? '—',
        gender: Gender.fromDb(s?['gender'] as String?),
        attendanceRecorded: att.containsKey(enrId),
        tasmeeRecorded: graded.contains(enrId),
        excuseRequested: requestedExcuses.contains(enrId),
        attendance: AttendanceStatus.fromDb(att[enrId] ?? 'present'),
        ledgerState: ledger[pid],
      );
    }).toList();

    return TodaySession(
      sessionId: sessionId,
      closedToday: today?['status'] == 'closed',
      presentCount: today?['present'] as int? ?? 0,
      absentCount: today?['absent'] as int? ?? 0,
      tasmeeCount: today?['tasmee'] as int? ?? 0,
      roster: roster,
      currentPortion: portion,
      activeAtOpen: cycle?.activeAtOpen ?? 0,
      requiredRevision: requiredRevision,
    );
  }

  Future<void> _cacheState() async {
    final TodaySession? value = state.asData?.value;
    if (value != null) {
      await ref
          .read(localDbProvider)
          .cacheSession(circleId, encodeTodaySession(value));
    }
  }

  Future<void> openSession() async {
    final TodaySession? current = state.asData?.value;
    if (current == null || current.isOpen) return;
    final String? personId = ref.read(currentPersonIdProvider).asData?.value;
    final String id = const Uuid().v4();
    try {
      await ref
          .read(sessionRepositoryProvider)
          .openSession(circleId, personId, sessionId: id);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      if (!isOfflineError(e)) rethrow;
      await ref
          .read(localDbProvider)
          .enqueue(
            OutboxOp(
              id: id,
              type: OutboxOpType.sessionOpen,
              payload: <String, dynamic>{
                'circle_id': circleId,
                'session_id': id,
                'opened_by': personId,
                'display_label': 'فتح حصة',
              },
            ),
          );
      state = AsyncData<TodaySession>(
        current.copyWith(
          sessionId: id,
          closedToday: false,
          roster: current.roster
              .map(
                (RosterEntry e) => e.copyWith(
                  attendance: AttendanceStatus.present,
                  attendanceRecorded: false,
                  tasmeeRecorded: false,
                  excuseRequested: false,
                ),
              )
              .toList(),
        ),
      );
      await _cacheState();
      await ref.read(outboxSyncProvider.notifier).flush();
    }
  }

  Future<void> setAttendance(
    String enrollmentId,
    AttendanceStatus status,
  ) async {
    final TodaySession? current = state.asData?.value;
    if (current == null || !current.isOpen) return;
    final RosterEntry entry = current.roster.firstWhere(
      (RosterEntry e) => e.enrollmentId == enrollmentId,
    );
    await ref
        .read(localDbProvider)
        .enqueue(
          OutboxOp(
            id: const Uuid().v4(),
            type: OutboxOpType.attendanceMark,
            payload: <String, dynamic>{
              'session_id': current.sessionId,
              'enrollment_id': enrollmentId,
              'status': status.dbValue,
              'display_label': '${entry.studentName} — حضور',
              'circle_id': circleId,
            },
          ),
        );
    final TodaySession latest = state.asData?.value ?? current;
    state = AsyncData<TodaySession>(
      latest.copyWith(
        roster: latest.roster
            .map(
              (RosterEntry e) => e.enrollmentId == enrollmentId
                  ? e.copyWith(attendance: status, attendanceRecorded: true)
                  : e,
            )
            .toList(),
      ),
    );
    await _cacheState();
    await ref.read(outboxSyncProvider.notifier).flush();
  }

  /// تحديد أول مقطع حفظ للحلقة (ينشئ مقطع + يفتح دورة + يجمّد المقام).
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

  /// نقل المجموعة لمقطع جديد (بعد تأكيد المعلّم) — يقفل الدورة الحالية ويفتح جديدة.
  Future<void> advance({
    required String name,
    required int surahStart,
    required int ayahStart,
    required int surahEnd,
    required int ayahEnd,
  }) async {
    final TodaySession? current = state.asData?.value;
    if (current == null) return;
    final double passRate = ProgressEngine.passRateForCycle(
      activeAtPortionOpen: current.activeAtOpen,
      passedCount: current.passedCount,
    );
    await ref
        .read(sessionRepositoryProvider)
        .advanceGroup(
          circleId: circleId,
          passRate: passRate,
          name: name,
          surahStart: surahStart,
          ayahStart: ayahStart,
          surahEnd: surahEnd,
          ayahEnd: ayahEnd,
        );
    ref.invalidateSelf();
    await future;
  }

  /// تسجيل تسميع لطالب (حفظ على المقطع الحالي أو مراجعة على مقطع المراجعة).
  /// [idempotencyKey] بييجي من الشيت (نفس المحاولة = نفس المفتاح عند الإعادة).
  Future<void> recordTasmee({
    required String enrollmentId,
    required String studentPersonId,
    required int score,
    required String idempotencyKey,
    TasmeeKind kind = TasmeeKind.memorization,
  }) async {
    final TodaySession? current = state.asData?.value;
    if (current == null) return;
    final Portion? portion = kind == TasmeeKind.revision
        ? current.requiredRevision
        : current.currentPortion;
    if (portion == null) return;
    // عتبة النجاح من الإعدادات، مع fallback للـ default لو الإعدادات ما تحمّلتش —
    // تسجيل التسميع فعل أساسي ومينفعش يفشل عشان الإعدادات.
    int threshold;
    try {
      threshold = (await ref.read(appSettingsProvider.future)).passThreshold;
    } catch (_) {
      threshold = ProgressEngine.defaultPassThreshold;
    }
    final bool passed = ProgressEngine.isPassing(
      score: score,
      threshold: threshold,
    );
    final String? teacherId = ref.read(currentPersonIdProvider).asData?.value;
    await ref
        .read(localDbProvider)
        .enqueue(
          OutboxOp(
            id: idempotencyKey,
            type: OutboxOpType.tasmeeRecord,
            payload: <String, dynamic>{
              'enrollment_id': enrollmentId,
              'student_person_id': studentPersonId,
              'portion_id': portion.id,
              'score': score,
              'passed': passed,
              'kind': kind.dbValue,
              'teacher_id': teacherId,
              'session_id': current.sessionId,
              'display_label':
                  '${current.roster.firstWhere((RosterEntry e) => e.studentPersonId == studentPersonId).studentName} — تسميع $score/١٠',
              'circle_id': circleId,
            },
          ),
        );
    final LedgerState? currentLedger = current.roster
        .firstWhere((RosterEntry e) => e.studentPersonId == studentPersonId)
        .ledgerState;
    final LedgerState next = passed || currentLedger == LedgerState.passed
        ? LedgerState.passed
        : LedgerState.failedRetry;
    // المراجعة مابتغيّرش الدَيْن → مفيش تحديث متفائل للروستر.
    if (kind == TasmeeKind.memorization) {
      final List<RosterEntry> roster = current.roster
          .map(
            (RosterEntry e) => e.studentPersonId == studentPersonId
                ? e.copyWith(ledgerState: next, tasmeeRecorded: true)
                : e,
          )
          .toList();
      state = AsyncData<TodaySession>(current.copyWith(roster: roster));
    }
    if (kind == TasmeeKind.revision) {
      state = AsyncData<TodaySession>(
        current.copyWith(
          roster: current.roster
              .map(
                (RosterEntry e) => e.studentPersonId == studentPersonId
                    ? e.copyWith(tasmeeRecorded: true)
                    : e,
              )
              .toList(),
        ),
      );
    }
    await _cacheState();
    await ref.read(outboxSyncProvider.notifier).flush();
  }

  /// قفل الحصة بخطة المراجعة الجاية + تسجيل حصيلة الحفظ النهارده (المقطع الحالي).
  Future<void> closeWithPlan({
    bool markUnrecordedPresent = true,
    String? revisionName,
    int? revSurahStart,
    int? revAyahStart,
    int? revSurahEnd,
    int? revAyahEnd,
  }) async {
    final TodaySession? current = state.asData?.value;
    final String? sessionId = current?.sessionId;
    if (current == null || sessionId == null || !current.isOpen) return;
    if (markUnrecordedPresent) {
      for (final RosterEntry entry in current.roster.where(
        (RosterEntry e) => !e.attendanceRecorded,
      )) {
        await ref
            .read(localDbProvider)
            .enqueue(
              OutboxOp(
                id: const Uuid().v4(),
                type: OutboxOpType.attendanceMark,
                payload: <String, dynamic>{
                  'session_id': sessionId,
                  'enrollment_id': entry.enrollmentId,
                  'status': AttendanceStatus.present.dbValue,
                  'display_label': '${entry.studentName} — حضور',
                  'circle_id': circleId,
                },
              ),
            );
      }
    }
    final String? teacherId = ref.read(currentPersonIdProvider).asData?.value;
    await ref
        .read(localDbProvider)
        .enqueue(
          OutboxOp(
            id: 'close-$sessionId',
            type: OutboxOpType.sessionClose,
            payload: <String, dynamic>{
              'session_id': sessionId,
              'circle_id': circleId,
              'revision_name': revisionName,
              'surah_start': revSurahStart,
              'ayah_start': revAyahStart,
              'surah_end': revSurahEnd,
              'ayah_end': revAyahEnd,
              'portion_id': current.currentPortion?.id,
              'teacher_id': teacherId,
              'display_label': 'قفل الحصة',
            },
          ),
        );
    final TodaySession closed = current.closedLocally(
      markUnrecordedPresent: markUnrecordedPresent,
    );
    state = AsyncData<TodaySession>(closed);
    await _cacheState();
    await ref.read(outboxSyncProvider.notifier).flush();
    if (await ref.read(localDbProvider).pendingCount() == 0) {
      ref.invalidateSelf();
      await future;
    }
  }

  /// المعلّم يسجّل ملاحظة سلوك لطالب. parent-visible بتبعت إشعار لولي الأمر
  /// (عبر الموصّل سيرفر-سايد)؛ مفيش تغيير على الروستر.
  Future<void> addBehavioralNote({
    required String studentPersonId,
    required String text,
    required String visibility,
  }) async {
    final String? teacherId = ref.read(currentPersonIdProvider).asData?.value;
    await ref
        .read(sessionRepositoryProvider)
        .addBehavioralNote(
          studentPersonId: studentPersonId,
          text: text,
          visibility: visibility,
          teacherId: teacherId,
        );
  }

  /// المعلّم يطلب عذر لطالب غايب → يدخل طابور المشرف.
  Future<void> requestExcuse(String enrollmentId, {String? reason}) async {
    final TodaySession? current = state.asData?.value;
    if (current == null ||
        !current.isOpen ||
        current.roster.any(
          (e) => e.enrollmentId == enrollmentId && e.excuseRequested,
        )) {
      return;
    }
    await ref
        .read(excuseRepositoryProvider)
        .createExcuse(
          enrollmentId: enrollmentId,
          sessionId: current.sessionId,
          reason: reason,
        );
    final TodaySession latest = state.asData?.value ?? current;
    if (latest.sessionId != current.sessionId) return;
    state = AsyncData<TodaySession>(
      latest.copyWith(
        roster: latest.roster
            .map(
              (RosterEntry e) => e.enrollmentId == enrollmentId
                  ? e.copyWith(excuseRequested: true)
                  : e,
            )
            .toList(),
      ),
    );
    await _cacheState();
  }
}
