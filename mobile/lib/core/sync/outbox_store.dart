import 'outbox_op.dart';

/// عملية فشلت نهائيًا (dead-letter) — تُعرض للمستخدم في شيت "حالة المزامنة"
/// مع سبب الفشل وإمكانية إعادة المحاولة.
class DeadLetterEntry {
  const DeadLetterEntry({
    required this.id,
    required this.type,
    required this.attempts,
    this.lastError,
  });

  final String id;
  final OutboxOpType type;
  final int attempts;
  final String? lastError;
}

/// لقطة عن حالة الطابور — لمؤشّر المزامنة في القشرة.
class SyncStatus {
  const SyncStatus({required this.pending, required this.dead});

  final int pending;
  final int dead;

  bool get hasPending => pending > 0;
  bool get hasFailures => dead > 0;
}

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

  /// عدد العمليات الميتة (فشل نهائي) — لمؤشّر "فشلت المزامنة".
  Future<int> deadLetterCount();

  /// العمليات الميتة (للعرض في شيت حالة المزامنة).
  Future<List<DeadLetterEntry>> deadLetters({int limit = 100});

  /// يرجّع عملية ميتة للطابور المعلّق (status='pending', attempts=0) عشان
  /// المستخدم يعيد المحاولة بعد ما يتصلح سبب الرفض.
  Future<void> requeue(String id);

  /// يتجاهل عملية ميتة نهائيًا (يشيلها من القاعدة) — إقرار من المستخدم إنها مش
  /// هتترجّع.
  Future<void> discard(String id);
}
