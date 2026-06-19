import 'outbox_op.dart';

/// مخزن طابور الإرسال — تجريد عشان المعالج يتختبر في Dart نقي (بدون Drift/sqlite).
/// التنفيذ الفعلي على القرص في `core/db/local_db.dart`.
abstract interface class OutboxStore {
  /// يضيف عملية للطابور (insert-or-ignore على [OutboxOp.id] = آمن للتكرار).
  Future<void> enqueue(OutboxOp op);

  /// العمليات المعلّقة بترتيب الإضافة (FIFO).
  Future<List<OutboxOp>> pending({int limit = 100});

  /// يعلّم العملية إنها اتزامنت بنجاح.
  Future<void> markSynced(String id);

  /// يزوّد عدّاد المحاولات ويسجّل آخر خطأ (العملية تفضل معلّقة لإعادة المحاولة).
  /// بيتنده على فشل عابر (النت مقطوع) — العملية هتتجرّب تاني.
  Future<void> markFailed(String id, String error);

  /// يحوّل العملية لـ "ميتة" (dead-letter): فشل نهائي (رفض السيرفر/تجاوز الحد) —
  /// بتتشال من الطابور المعلّق عشان ما تسدّش اللي وراها، ويتسجّل سببها.
  Future<void> markDeadLetter(String id, String error);

  /// عدد العمليات المعلّقة (لمؤشّر "في انتظار المزامنة").
  Future<int> pendingCount();
}
