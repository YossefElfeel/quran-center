import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/local_db.dart';
import '../../../core/network/network_status.dart';
import '../../../core/sync/outbox_op.dart';
import '../../../core/sync/outbox_processor.dart';
import '../domain/tasmee_kind.dart';
import 'session_repository.dart';

part 'session_sync.g.dart';

/// يبعت عملية واحدة من الطابور للسيرفر حسب نوعها. بيرمي لو فشلت (المعالج يوقف).
Future<void> dispatchSessionOp(Ref ref, OutboxOp op) async {
  final SessionRepository repo = ref.read(sessionRepositoryProvider);
  final Map<String, dynamic> p = op.payload;
  switch (op.type) {
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

  @override
  void build() {
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
        unawaited(_processor.flush());
      }
    });
    // محاولة تفريغ عند البدء (لو فيه معلّق من جلسة سابقة).
    unawaited(Future<void>.microtask(_processor.flush));
  }

  /// تفريغ يدوي (مثلًا بعد إضافة عملية وإحنا أونلاين).
  Future<void> flush() => _processor.flush();
}
