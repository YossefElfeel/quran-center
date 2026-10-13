import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/local_db.dart';
import '../../../core/network/network_status.dart';
import '../../../core/sync/outbox_op.dart';
import '../../../core/sync/outbox_processor.dart';
import '../../../core/sync/outbox_store.dart';
import '../../../core/sync/sync_status_provider.dart';
import '../domain/session_write_block.dart';
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

/// عابر = النت مقطوع أو الإدارة موقفة التسجيل مؤقتًا → العملية تفضل معلّقة
/// ويتعاد إرسالها؛ غير كده (رفض السيرفر) → dead-letter.
bool isTransientSyncError(Object error) =>
    error is SessionWritesBlockedException || isOfflineError(error);

/// يحوّل رفض الصلاحية (42501) لـ [SessionWritesBlockedException] لو السبب
/// تجميد/صيانة من الإدارة، وإلا يرجّع الخطأ زي ما هو. أفضل-جهد: لو سؤال السيرفر
/// فشل (الـ RPC مش موجودة مثلًا) الخطأ الأصلي هو اللي بيطلع.
Future<Object> explainSessionWriteError(
  Object error,
  Future<SessionWriteBlock?> Function() lookup,
) async {
  if (error is SessionWritesBlockedException ||
      !isPermissionDeniedError(error)) {
    return error;
  }
  final SessionWriteBlock? block = await lookup();
  return block == null ? error : SessionWritesBlockedException(block);
}

/// سبب إيقاف المزامنة الحالي (تجميد/صيانة) — null = شغّالة عادي. يتحدّث من
/// [OutboxSync] ويتعرض في شيت حالة المزامنة.
@Riverpod(keepAlive: true)
class SessionWritesBlockState extends _$SessionWritesBlockState {
  @override
  SessionWriteBlock? build() => null;

  void set(SessionWriteBlock? block) {
    if (state != block) state = block;
  }
}

/// مزامن الطابور: يفرّغ المعلّق أول ما النت يرجع + محاولة عند بدء التطبيق.
/// يتفعّل من جذر التطبيق (`ref.watch`) عشان يفضل شغّال طول الجلسة.
@Riverpod(keepAlive: true)
class OutboxSync extends _$OutboxSync {
  // Rebuilt on every build(): a `late final` field would throw if Riverpod
  // re-runs build (e.g. when localDbProvider changes).
  OutboxProcessor? _processor;
  AppLifecycleListener? _lifecycle;
  Timer? _retryTimer;
  int _backoff = 1;
  bool _disposed = false;
  Future<void>? _flush;

  /// فاصل إعادة المحاولة أثناء إيقاف الإدارة — ثابت (من غير backoff متصاعد).
  static const Duration blockedRetry = Duration(minutes: 5);

  @override
  void build() {
    _disposed = false;
    _lifecycle?.dispose();
    final AppLifecycleListener lifecycle = AppLifecycleListener(
      onResume: () {
        _backoff = 1;
        unawaited(flush());
      },
    );
    _lifecycle = lifecycle;
    ref.onDispose(() {
      _disposed = true;
      _retryTimer?.cancel();
      lifecycle.dispose();
      if (identical(_lifecycle, lifecycle)) _lifecycle = null;
    });
    _processor = OutboxProcessor(
      ref.watch(localDbProvider),
      _dispatch,
      // عابر (نت مقطوع/إيقاف إداري) → يقف ويعيد؛ رفض نهائي → dead-letter ويكمّل.
      isTransient: isTransientSyncError,
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

  Future<void> _dispatch(OutboxOp op) async {
    try {
      await dispatchSessionOp(ref, op);
    } catch (e) {
      final Object explained = await explainSessionWriteError(
        e,
        ref.read(sessionRepositoryProvider).sessionWritesBlocked,
      );
      if (explained is SessionWritesBlockedException && !_disposed) {
        ref
            .read(sessionWritesBlockStateProvider.notifier)
            .set(explained.reason);
      }
      throw explained;
    }
    if (!_disposed) {
      ref.read(sessionWritesBlockStateProvider.notifier).set(null);
    }
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
    final OutboxProcessor? processor = _processor;
    if (processor == null) return;
    final LocalDb db = ref.read(localDbProvider);
    _retryTimer?.cancel();
    final int before = await db.pendingCount();
    final int deadBefore = before > 0 ? await db.deadLetterCount() : 0;
    bool flushed = false;
    try {
      await processor.flush();
      flushed = true;
    } finally {
      final int pending = _disposed ? 0 : await db.pendingCount();
      // "آخر مزامنة" = كان فيه معلّق، اتفرّغ، وواحدة ع الأقل اتقبلت فعلًا
      // (مش كله اترفض ودخل الـ dead-letter).
      if (flushed && !_disposed && before > 0 && pending == 0) {
        final int newlyDead = await db.deadLetterCount() - deadBefore;
        if (!_disposed && newlyDead < before) {
          unawaited(ref.read(lastSyncAtProvider.notifier).markNow());
        }
      }
      if (_disposed || pending == 0) {
        _backoff = 1;
      } else if (ref.read(sessionWritesBlockStateProvider) != null) {
        // الإدارة موقفة التسجيل: مفيش داعي نضغط على السيرفر — محاولة هادية
        // كل شوية + عند رجوع التطبيق/النت/أي تسجيل جديد.
        _backoff = 1;
        _retryTimer = Timer(blockedRetry, () => unawaited(flush()));
      } else {
        _retryTimer = Timer(
          Duration(seconds: 30 * _backoff),
          () => unawaited(flush()),
        );
        _backoff = (_backoff * 2).clamp(1, 8);
      }
    }
  }
}
