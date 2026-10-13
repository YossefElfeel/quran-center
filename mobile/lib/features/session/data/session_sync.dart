import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/local_db.dart';
import '../../../core/network/network_status.dart';
import '../../../core/sync/outbox_op.dart';
import '../../../core/sync/outbox_processor.dart';
import '../../../core/sync/outbox_store.dart';
import '../../../core/sync/sync_status_provider.dart';
import '../domain/tasmee_kind.dart';
import 'session_repository.dart';

part 'session_sync.g.dart';

/// يبعت عملية واحدة من الطابور للسيرفر حسب نوعها. بيرمي لو فشلت (المعالج يوقف).
Future<void> dispatchSessionOp(Ref ref, OutboxOp op) async {
  final SessionRepository repo = ref.read(sessionRepositoryProvider);
  final Map<String, dynamic> p = op.payload;
  switch (op.type) {
    case OutboxOpType.sessionOpen:
      await repo.openSession(
        p['circle_id'] as String,
        p['opened_by'] as String?,
        sessionId: p['session_id'] as String,
      );
    case OutboxOpType.sessionClose:
      await repo.closeSessionWithPlan(
        circleId: p['circle_id'] as String,
        sessionId: p['session_id'] as String,
        revisionName: p['revision_name'] as String?,
        revSurahStart: p['surah_start'] as int?,
        revAyahStart: p['ayah_start'] as int?,
        revSurahEnd: p['surah_end'] as int?,
        revAyahEnd: p['ayah_end'] as int?,
        memorizedTodayPortionId: p['portion_id'] as String?,
        teacherId: p['teacher_id'] as String?,
      );
    case OutboxOpType.tasmeeRecord:
      // op.id هو نفسه idempotency_key → إعادة الإرسال آمنة (السيرفر do nothing).
      await repo.recordTasmee(
        enrollmentId: p['enrollment_id'] as String,
        studentPersonId: p['student_person_id'] as String,
        portionId: p['portion_id'] as String,
        score: p['score'] as int,
        passed: p['passed'] as bool,
        idempotencyKey: op.id,
        kind: TasmeeKind.fromDb(p['kind'] as String),
        teacherId: p['teacher_id'] as String?,
        sessionId: p['session_id'] as String?,
      );
    case OutboxOpType.attendanceMark:
      // upsert على (session_id, enrollment_id) → آمن للتكرار.
      await repo.setAttendance(
        sessionId: p['session_id'] as String,
        enrollmentId: p['enrollment_id'] as String,
        status: p['status'] as String,
      );
  }
}

/// مزامن الطابور: يفرّغ المعلّق أول ما النت يرجع + محاولة عند بدء التطبيق.
/// يتفعّل من جذر التطبيق (`ref.watch`) عشان يفضل شغّال طول الجلسة.
@Riverpod(keepAlive: true)
class OutboxSync extends _$OutboxSync {
  late final OutboxProcessor _processor;
  Timer? _retryTimer;
  int _backoff = 1;
  bool _disposed = false;
  Future<void>? _flush;

  @override
  void build() {
    _disposed = false;
    final AppLifecycleListener lifecycle = AppLifecycleListener(
      onResume: () {
        _backoff = 1;
        unawaited(flush());
      },
    );
    ref.onDispose(() {
      _disposed = true;
      _retryTimer?.cancel();
      lifecycle.dispose();
    });
    _processor = OutboxProcessor(
      ref.watch(localDbProvider),
      (OutboxOp op) => dispatchSessionOp(ref, op),
      // عابر = النت مقطوع → يقف ويعيد؛ غير كده (رفض السيرفر) → dead-letter ويكمّل.
      isTransient: isOfflineError,
    );
    // افرّغ أول ما الاتصال يرجع.
    ref.listen<AsyncValue<bool>>(connectivityOnlineProvider, (
      AsyncValue<bool>? previous,
      AsyncValue<bool> next,
    ) {
      if (next.value ?? false) {
        _backoff = 1;
        unawaited(flush());
      }
    });
    ref.listen<AsyncValue<SyncStatus>>(syncStatusProvider, (
      AsyncValue<SyncStatus>? previous,
      AsyncValue<SyncStatus> next,
    ) {
      if ((next.asData?.value.pending ?? 0) >
          (previous?.asData?.value.pending ?? 0)) {
        _backoff = 1;
        unawaited(flush());
      }
    });
    // محاولة تفريغ عند البدء (لو فيه معلّق من جلسة سابقة).
    unawaited(Future<void>.microtask(flush));
  }

  /// تفريغ يدوي (مثلًا بعد إضافة عملية وإحنا أونلاين).
  Future<void> flush() {
    if (_disposed) return Future<void>.value();
    if (_flush != null) return _flush!;
    final Future<void> running = _flushOnce();
    _flush = running;
    return running.whenComplete(() => _flush = null);
  }

  Future<void> _flushOnce() async {
    final LocalDb db = ref.read(localDbProvider);
    _retryTimer?.cancel();
    try {
      await _processor.flush();
    } finally {
      final int pending = _disposed ? 0 : await db.pendingCount();
      if (!_disposed && pending > 0) {
        _retryTimer = Timer(
          Duration(seconds: 30 * _backoff),
          () => unawaited(flush()),
        );
        _backoff = (_backoff * 2).clamp(1, 8);
      } else {
        _backoff = 1;
      }
    }
  }
}
