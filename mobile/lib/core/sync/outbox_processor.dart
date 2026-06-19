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
/// - **تجاوز [maxAttempts]** (احتياطي ضد عملية بتفشل كأنها عابرة بلا نهاية) →
///   dead-letter وكمّل، عشان الطابور ما يتقفلش للأبد.
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
  bool _running = false;

  Future<void> flush() async {
    if (_running) return;
    _running = true;
    try {
      final List<OutboxOp> ops = await _store.pending();
      for (final OutboxOp op in ops) {
        try {
          await _dispatch(op);
          await _store.markSynced(op.id);
        } catch (e) {
          if (!isTransient(e)) {
            // فشل نهائي → اشطبها وكمّل (ما تسدّش اللي وراها).
            await _store.markDeadLetter(op.id, e.toString());
            continue;
          }
          if (op.attempts + 1 >= maxAttempts) {
            // عابر بس بيتكرّر كتير → احتياطي: اشطبها وكمّل عشان الطابور يتحرّك.
            await _store.markDeadLetter(op.id, 'max attempts: $e');
            continue;
          }
          // عابر (النت مقطوع) → سجّل المحاولة ووقف للحفاظ على FIFO.
          await _store.markFailed(op.id, e.toString());
          break;
        }
      }
    } finally {
      _running = false;
    }
  }
}
