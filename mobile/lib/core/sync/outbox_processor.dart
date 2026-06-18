import 'outbox_op.dart';
import 'outbox_store.dart';

/// دالة إرسال عملية واحدة للسيرفر — بترمي لو فشلت (السبب الأغلب: النت لسه مقطوع).
typedef OutboxDispatch = Future<void> Function(OutboxOp op);

/// يفرّغ طابور الإرسال FIFO: ينده [dispatch] لكل عملية معلّقة.
/// النجاح → `markSynced`؛ الفشل → `markFailed` ثم **يقف** (الأرجح النت لسه
/// مقطوع) للحفاظ على ترتيب FIFO وعدم تخطّي عملية فاشلة.
///
/// `flush` ممنوع الدخول عليها بالتوازي (`_running`) عشان ما نبعتش نفس العملية
/// مرّتين من تشغيلين متزامنين (connectivity + بدء التطبيق مثلًا).
class OutboxProcessor {
  OutboxProcessor(this._store, this._dispatch);

  final OutboxStore _store;
  final OutboxDispatch _dispatch;
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
          await _store.markFailed(op.id, e.toString());
          break;
        }
      }
    } finally {
      _running = false;
    }
  }
}
