import 'ledger_state.dart';

/// نتيجة تقييم انتقال المجموعة.
class AdvanceEvaluation {
  const AdvanceEvaluation({
    required this.passRate,
    required this.shouldAdvance,
  });

  final double passRate;
  final bool shouldAdvance;
}

/// محرّك الحفظ — منطق نقي (بدون Supabase/Flutter) قابل للاختبار بالكامل.
///
/// القواعد:
/// - التسميع نجاح لو الدرجة >= حد النجاح (افتراضي ٧).
/// - المجموعة تنتقل لو **أكتر من ٥٠٪** من النشطين عدّوا المقطع الحالي،
///   والمقام **مجمّد** على عدد النشطين وقت فتح المقطع (مش وقت الحساب).
/// - اللي ماعداش يفضل المقطع دَيْن عليه (failed_retry) لحد ما يعدّيه.
abstract final class ProgressEngine {
  const ProgressEngine._();

  /// عتبة الانتقال (٥٠٪، حصري — لازم تتعدّى مش تتساوى).
  static const double advanceThreshold = 0.5;

  /// نجح التسميع؟
  static bool isPassing({required int score, required int threshold}) =>
      score >= threshold;

  /// تقييم انتقال المجموعة على المقطع الحالي.
  /// [activeAtPortionOpen] = المقام المجمّد (النشطون وقت فتح المقطع).
  /// [passedCount] = عدد اللي عدّوا المقطع من دول.
  static AdvanceEvaluation evaluateAdvance({
    required int activeAtPortionOpen,
    required int passedCount,
  }) {
    if (activeAtPortionOpen <= 0) {
      return const AdvanceEvaluation(passRate: 0, shouldAdvance: false);
    }
    final int passed = passedCount.clamp(0, activeAtPortionOpen);
    final double rate = passed / activeAtPortionOpen;
    return AdvanceEvaluation(
      passRate: rate,
      shouldAdvance: rate > advanceThreshold,
    );
  }

  /// حالة الدَيْن الجديدة بعد محاولة تسميع.
  static LedgerState nextLedgerState({
    required LedgerState current,
    required bool passed,
  }) {
    if (current == LedgerState.passed) return LedgerState.passed;
    if (passed) return LedgerState.passed;
    return LedgerState.failedRetry;
  }

  /// تنبيه التعثّر: عدد مرّات الرسوب وصل للحد (افتراضي ٣).
  static bool isStruggling({
    required int failedAttempts,
    required int threshold,
  }) => failedAttempts >= threshold;
}
