import 'outbox_op.dart';
import 'outbox_store.dart';

/// دالة إرسال عملية واحدة للسيرفر — بترمي لو فشلت.
typedef OutboxDispatch = Future<void> Function(OutboxOp op);

/// يصنّف الخطأ: true = عابر (النت مقطوع، يستاهل إعادة محاولة)، false = نهائي
/// (رفض السيرفر/تحقق — مش هيتحسّن بإعادة المحاولة).
typedef TransientClassifier = bool Function(Object error);

/// يفرّغ طابور الإرسال FIFO: ينده [dispatch] لكل عملية معلّقة.
///
/// التعامل مع الفشل (إصلاح head-of-line blocking):
/// - **فشل عابر** (النت مقطوع) → `markFailed` (يزوّد العدّاد) ثم **يقف** للحفاظ
///   على ترتيب FIFO؛ يعاد المحاولة عند رجوع النت.
/// - **فشل نهائي** (رفض السيرفر: صلاحية/قيد/4xx) → `markDeadLetter` ثم **يكمّل**
///   للعملية اللي بعدها — عشان عملية مرفوضة ما تسدّش الطابور للأبد.
/// - الانقطاع الممتد يحتفظ بالعمليات المعلّقة؛ [maxAttempts] محفوظ للتوافق فقط.
///
/// `flush` ممنوع الدخول عليها بالتوازي (`_running`).
class OutboxProcessor {
  OutboxProcessor(
    this._store,
    this._dispatch, {
    required this.isTransient,
    this.maxAttempts = 25,
  });

  final OutboxStore _store;
  final OutboxDispatch _dispatch;
  final TransientClassifier isTransient;
  final int maxAttempts;

  Future<void>? _inflight;
  Future<void> flush() =>
      _inflight ??= _drain().whenComplete(() => _inflight = null);
  Future<void> _drain() async {
    final List<DeadLetterEntry> dead = await _store.deadLetters(limit: 100000);
    final Set<String> blockedClose = <String>{
      for (final entry in dead)
        if (entry.sessionId != null && entry.type != OutboxOpType.sessionClose)
          entry.sessionId!,
    };
    final Set<String> blockedSession = <String>{
      for (final entry in dead)
        if (entry.sessionId != null && entry.type == OutboxOpType.sessionOpen)
          entry.sessionId!,
    };
    while (true) {
      final List<OutboxOp> ops = await _store.pending();
      if (ops.isEmpty) return;
      for (final OutboxOp op in ops) {
        final String? sessionId = op.payload['session_id'] as String?;
        if (sessionId != null &&
            (blockedSession.contains(sessionId) ||
                (op.type == OutboxOpType.sessionClose &&
                    blockedClose.contains(sessionId)))) {
          await _store.markDeadLetter(
            op.id,
            'dependent session operation failed — retry the earlier records first',
          );
          continue;
        }
        try {
          await _dispatch(op);
          await _store.markSynced(op.id);
        } catch (e) {
          if (!isTransient(e)) {
            await _store.markDeadLetter(op.id, e.toString());
            if (sessionId != null) {
              blockedClose.add(sessionId);
              if (op.type == OutboxOpType.sessionOpen) {
                blockedSession.add(sessionId);
              }
            }
            continue;
          }
          // An extended outage must never turn a saved grade into discarded work.
          await _store.markFailed(op.id, e.toString());
          return;
        }
      }
    }
  }
}
