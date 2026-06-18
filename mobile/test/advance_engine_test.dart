import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/progress_engine/domain/ledger_state.dart';
import 'package:quran_center/features/progress_engine/domain/progress_engine.dart';

void main() {
  group('suggestAdvance — المقام المجمّد + عتبة ٥٠٪ حصري', () {
    test('بالظبط ٥٠٪ → مفيش اقتراح (حصري)', () {
      final AdvanceSuggestion r = ProgressEngine.suggestAdvance(
        activeAtOpen: 4,
        passedCount: 2,
      );
      expect(r.passRate, 0.5);
      expect(r.meetsThreshold, isFalse);
      expect(r.suggestAdvance, isFalse);
    });

    test('فوق الـ٥٠٪ بشعرة (٣ من ٥) → اقتراح', () {
      final AdvanceSuggestion r = ProgressEngine.suggestAdvance(
        activeAtOpen: 5,
        passedCount: 3,
      );
      expect(r.passRate, 0.6);
      expect(r.meetsThreshold, isTrue);
      expect(r.suggestAdvance, isTrue);
    });

    test('تحت الـ٥٠٪ (٢ من ٥) → مفيش اقتراح', () {
      final AdvanceSuggestion r = ProgressEngine.suggestAdvance(
        activeAtOpen: 5,
        passedCount: 2,
      );
      expect(r.meetsThreshold, isFalse);
      expect(r.suggestAdvance, isFalse);
    });

    test('الكل عدّى → اقتراح ومعدّل ١٫٠', () {
      final AdvanceSuggestion r = ProgressEngine.suggestAdvance(
        activeAtOpen: 6,
        passedCount: 6,
      );
      expect(r.passRate, 1.0);
      expect(r.suggestAdvance, isTrue);
    });

    test('حالة فردي: ٢ من ٣ (فوق النص) → اقتراح', () {
      final AdvanceSuggestion r = ProgressEngine.suggestAdvance(
        activeAtOpen: 3,
        passedCount: 2,
      );
      expect(r.meetsThreshold, isTrue);
      expect(r.suggestAdvance, isTrue);
    });

    test('حالة فردي: ١ من ٣ (تحت النص) → مفيش اقتراح', () {
      final AdvanceSuggestion r = ProgressEngine.suggestAdvance(
        activeAtOpen: 3,
        passedCount: 1,
      );
      expect(r.meetsThreshold, isFalse);
      expect(r.suggestAdvance, isFalse);
    });
  });

  group('suggestAdvance — صفر نشطين', () {
    test('مفيش نشطين → مفيش اقتراح والمعدّل صفر', () {
      final AdvanceSuggestion r = ProgressEngine.suggestAdvance(
        activeAtOpen: 0,
        passedCount: 0,
      );
      expect(r.passRate, 0);
      expect(r.suggestAdvance, isFalse);
      expect(r.meetsThreshold, isFalse);
      expect(r.meetsMinActive, isFalse);
    });

    test('مقام سالب (حماية) → مفيش اقتراح', () {
      final AdvanceSuggestion r = ProgressEngine.suggestAdvance(
        activeAtOpen: -3,
        passedCount: 5,
      );
      expect(r.passRate, 0);
      expect(r.suggestAdvance, isFalse);
    });
  });

  group('suggestAdvance — المقام المجمّد بيستبعد الانضمام وسط الدورة', () {
    test('المقام ثابت على عدد فتح المقطع مهما زاد النشطون', () {
      // فتح المقطع بـ٤ نشطين (المقام المجمّد). عدّى منهم ٣ → فوق النص.
      final AdvanceSuggestion frozen = ProgressEngine.suggestAdvance(
        activeAtOpen: 4,
        passedCount: 3,
      );
      expect(frozen.passRate, 0.75);
      expect(frozen.suggestAdvance, isTrue);

      // لو حسبنا على عدد جديد (٦ بعد ما انضم ٢ وسط الدورة) نفس الـ٣ عدّوا
      // → النتيجة هتختلف. ده بيثبت إن المقام بيتجمّد ولا يتأثر بالمنضمّين.
      final AdvanceSuggestion live = ProgressEngine.suggestAdvance(
        activeAtOpen: 6,
        passedCount: 3,
      );
      expect(live.passRate, 0.5);
      expect(live.suggestAdvance, isFalse);
      expect(frozen.suggestAdvance, isNot(live.suggestAdvance));
    });

    test('المنضمّون وسط الدورة مش بيقدروا يعدّوا فوق المقام (يتقصّ)', () {
      // المقام المجمّد ٣، لكن وصلنا ٥ نجاحات (بإحتساب منضمّين بالغلط) → يتقصّ ٣.
      final AdvanceSuggestion r = ProgressEngine.suggestAdvance(
        activeAtOpen: 3,
        passedCount: 5,
      );
      expect(r.passRate, 1.0);
      expect(r.suggestAdvance, isTrue);
    });
  });

  group('suggestAdvance — حارس الحد الأدنى للنشطين', () {
    test('فوق النص بس تحت الحد الأدنى → مفيش اقتراح', () {
      // ١ من ١ = ١٠٠٪ لكن الحد الأدنى ٣ → مايتقترحش.
      final AdvanceSuggestion r = ProgressEngine.suggestAdvance(
        activeAtOpen: 1,
        passedCount: 1,
        minActive: 3,
      );
      expect(r.meetsThreshold, isTrue);
      expect(r.meetsMinActive, isFalse);
      expect(r.suggestAdvance, isFalse);
    });

    test('عند الحد الأدنى بالظبط + فوق النص → اقتراح', () {
      final AdvanceSuggestion r = ProgressEngine.suggestAdvance(
        activeAtOpen: 3,
        passedCount: 2,
        minActive: 3,
      );
      expect(r.meetsMinActive, isTrue);
      expect(r.meetsThreshold, isTrue);
      expect(r.suggestAdvance, isTrue);
    });

    test('فوق الحد الأدنى بس تحت النص → مفيش اقتراح', () {
      final AdvanceSuggestion r = ProgressEngine.suggestAdvance(
        activeAtOpen: 5,
        passedCount: 2,
        minActive: 3,
      );
      expect(r.meetsMinActive, isTrue);
      expect(r.meetsThreshold, isFalse);
      expect(r.suggestAdvance, isFalse);
    });

    test('الحد الأدنى الافتراضي ١ → نشط واحد عدّى يقترح', () {
      final AdvanceSuggestion r = ProgressEngine.suggestAdvance(
        activeAtOpen: 1,
        passedCount: 1,
      );
      expect(r.meetsMinActive, isTrue);
      expect(r.suggestAdvance, isTrue);
    });
  });

  group('passRateForCycle — تقريب وقصّ لـnumeric(4,3)', () {
    test('٢ من ٣ → ٠٫٦٦٧ (تقريب لأعلى)', () {
      final double rate = ProgressEngine.passRateForCycle(
        activeAtPortionOpen: 3,
        passedCount: 2,
      );
      expect(rate, 0.667);
    });

    test('١ من ٣ → ٠٫٣٣٣ (تقريب لأسفل)', () {
      final double rate = ProgressEngine.passRateForCycle(
        activeAtPortionOpen: 3,
        passedCount: 1,
      );
      expect(rate, 0.333);
    });

    test('١ من ٦ → ٠٫١٦٧', () {
      final double rate = ProgressEngine.passRateForCycle(
        activeAtPortionOpen: 6,
        passedCount: 1,
      );
      expect(rate, 0.167);
    });

    test('٥ من ٦ → ٠٫٨٣٣', () {
      final double rate = ProgressEngine.passRateForCycle(
        activeAtPortionOpen: 6,
        passedCount: 5,
      );
      expect(rate, 0.833);
    });

    test('الكل عدّى → ١٫٠ بالظبط', () {
      final double rate = ProgressEngine.passRateForCycle(
        activeAtPortionOpen: 4,
        passedCount: 4,
      );
      expect(rate, 1.0);
    });

    test('مفيش نشطين → ٠', () {
      final double rate = ProgressEngine.passRateForCycle(
        activeAtPortionOpen: 0,
        passedCount: 0,
      );
      expect(rate, 0);
    });

    test('passedCount أكبر من المقام يتقصّ → ١٫٠ (مش فوق الواحد)', () {
      final double rate = ProgressEngine.passRateForCycle(
        activeAtPortionOpen: 3,
        passedCount: 99,
      );
      expect(rate, 1.0);
    });

    test('المعدّل دايمًا في النطاق [0..1]', () {
      final double rate = ProgressEngine.passRateForCycle(
        activeAtPortionOpen: 7,
        passedCount: 4,
      );
      expect(rate, greaterThanOrEqualTo(0.0));
      expect(rate, lessThanOrEqualTo(1.0));
      expect(rate, 0.571);
    });
  });

  group('roundTo3 — مطابق لـnumeric(4,3)', () {
    test('بيقطع لـ٣ خانات مع تقريب', () {
      expect(ProgressEngine.roundTo3(0.6666666), 0.667);
      expect(ProgressEngine.roundTo3(0.3333333), 0.333);
      expect(ProgressEngine.roundTo3(0.5), 0.5);
      expect(ProgressEngine.roundTo3(1.0), 1.0);
      expect(ProgressEngine.roundTo3(0.0), 0.0);
    });
  });

  group('passRate متّسق بين suggestAdvance و passRateForCycle', () {
    test('نفس المدخلات → نفس المعدّل المتقرّب', () {
      final AdvanceSuggestion s = ProgressEngine.suggestAdvance(
        activeAtOpen: 7,
        passedCount: 5,
      );
      final double cycle = ProgressEngine.passRateForCycle(
        activeAtPortionOpen: 7,
        passedCount: 5,
      );
      expect(s.passRate, cycle);
      expect(s.passRate, 0.714);
    });
  });

  group('ثابت الدَيْن — اللي ماعداش يفضل دَيْن مفتوح بعد الانتقال', () {
    test('غير الناجح في المقطع المقفول يفضل failed_retry بعد رسوبه', () {
      // طالب راسب على المقطع وقت ما المجموعة اتنقلت → دَيْن مفتوح.
      final LedgerState afterFail = ProgressEngine.nextLedgerState(
        current: LedgerState.assigned,
        passed: false,
      );
      expect(afterFail, LedgerState.failedRetry);

      // المجموعة اتنقلت (الانتقال مالوش علاقة بدفتر الفرد) →
      // محاولة لاحقة راسبة تفضل failed_retry (الدَيْن باقي).
      final LedgerState stillDebt = ProgressEngine.nextLedgerState(
        current: afterFail,
        passed: false,
      );
      expect(stillDebt, LedgerState.failedRetry);
    });

    test('الناجح في المقطع يفضل passed حتى لو راجع بعد الانتقال', () {
      final LedgerState passed = ProgressEngine.nextLedgerState(
        current: LedgerState.passed,
        passed: false,
      );
      expect(passed, LedgerState.passed);
    });

    test('غير الناجح يقدر يسدّ الدَيْن بعد الانتقال بتسميع ناجح', () {
      final LedgerState cleared = ProgressEngine.nextLedgerState(
        current: LedgerState.failedRetry,
        passed: true,
      );
      expect(cleared, LedgerState.passed);
    });
  });
}
