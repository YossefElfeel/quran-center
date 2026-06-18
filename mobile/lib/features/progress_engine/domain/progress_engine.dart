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

/// اقتراح انتقال المجموعة (بقرار بشري — لازم تأكيد المعلّم).
///
/// بيتبني على المقام المجمّد (النشطون وقت فتح المقطع) + حد أدنى للنشطين.
/// [passRate] هو معدّل النجاح اللي هيتخزّن على المقطع المقفول
/// (numeric(4,3) — متقرّب لـ٣ خانات).
class AdvanceSuggestion {
  const AdvanceSuggestion({
    required this.passRate,
    required this.suggestAdvance,
    required this.meetsThreshold,
    required this.meetsMinActive,
  });

  /// معدّل النجاح (٠..١) متقرّب لـ٣ خانات عشرية.
  final double passRate;

  /// نقترح الانتقال؟ (لازم تجاوز العتبة **و** تحقّق الحد الأدنى للنشطين).
  final bool suggestAdvance;

  /// اتجاوزت عتبة الـ٥٠٪ (حصري)؟
  final bool meetsThreshold;

  /// اتحقّق الحد الأدنى للنشطين؟
  final bool meetsMinActive;
}

/// محرّك الحفظ — منطق نقي (بدون Supabase/Flutter) قابل للاختبار بالكامل.
///
/// القواعد:
/// - التسميع نجاح لو الدرجة >= حد النجاح (افتراضي ٧).
/// - المجموعة تنتقل لو **أكتر من ٥٠٪** من النشطين عدّوا المقطع الحالي،
///   والمقام **مجمّد** على عدد النشطين وقت فتح المقطع (مش وقت الحساب).
/// - الانتقال **اقتراح** لازم يأكّده المعلّم، وبشرط حد أدنى للنشطين.
/// - اللي ماعداش يفضل المقطع دَيْن عليه (failed_retry) لحد ما يعدّيه.
abstract final class ProgressEngine {
  const ProgressEngine._();

  /// عتبة الانتقال (٥٠٪، حصري — لازم تتعدّى مش تتساوى).
  static const double advanceThreshold = 0.5;

  /// حد النجاح الافتراضي للتسميع (/١٠) — قابل للضبط لكل منهج لاحقًا.
  static const int defaultPassThreshold = 7;

  /// الحد الأدنى الافتراضي لعدد النشطين قبل ما نقترح انتقال.
  static const int defaultMinActive = 1;

  /// حد التعثّر الافتراضي: عدد مرّات الرسوب اللي بعدها الطالب "محتاج انتباه".
  static const int defaultStruggleThreshold = 3;

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

  /// معدّل النجاح اللي يتخزّن على المقطع المقفول (group_portion_cycle.pass_rate).
  /// مقصوص على [0..1] ومتقرّب لـ٣ خانات عشرية (العمود numeric(4,3)).
  /// مقام صفر/سالب → ٠.
  static double passRateForCycle({
    required int activeAtPortionOpen,
    required int passedCount,
  }) {
    if (activeAtPortionOpen <= 0) return 0;
    final int passed = passedCount.clamp(0, activeAtPortionOpen);
    final double rate = (passed / activeAtPortionOpen).clamp(0.0, 1.0);
    return roundTo3(rate);
  }

  /// تقريب لـ٣ خانات عشرية (مطابق لـnumeric(4,3) في الداتابيز).
  static double roundTo3(double value) => (value * 1000).roundToDouble() / 1000;

  /// اقتراح انتقال المجموعة (قرار بشري — تأكيد المعلّم مطلوب).
  ///
  /// [activeAtOpen] = المقام المجمّد (النشطون وقت فتح المقطع).
  /// [passedCount]  = عدد اللي عدّوا المقطع من المقام المجمّد.
  /// [minActive]    = الحد الأدنى للنشطين قبل ما نقترح (افتراضي ١).
  ///
  /// نقترح الانتقال لو: [activeAtOpen] > 0 **و** المعدّل > ٥٠٪ (حصري)
  /// **و** [activeAtOpen] >= [minActive].
  static AdvanceSuggestion suggestAdvance({
    required int activeAtOpen,
    required int passedCount,
    int minActive = defaultMinActive,
  }) {
    if (activeAtOpen <= 0) {
      return const AdvanceSuggestion(
        passRate: 0,
        suggestAdvance: false,
        meetsThreshold: false,
        meetsMinActive: false,
      );
    }
    final int passed = passedCount.clamp(0, activeAtOpen);
    final double rawRate = passed / activeAtOpen;
    final bool meetsThreshold = rawRate > advanceThreshold;
    final bool meetsMinActive = activeAtOpen >= minActive;
    return AdvanceSuggestion(
      passRate: roundTo3(rawRate),
      suggestAdvance: meetsThreshold && meetsMinActive,
      meetsThreshold: meetsThreshold,
      meetsMinActive: meetsMinActive,
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
