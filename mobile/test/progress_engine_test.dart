import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/progress_engine/domain/ledger_state.dart';
import 'package:quran_center/features/progress_engine/domain/progress_engine.dart';

void main() {
  group('isPassing', () {
    test('الدرجة == الحد → نجاح', () {
      expect(ProgressEngine.isPassing(score: 7, threshold: 7), isTrue);
    });
    test('الدرجة أقل من الحد → رسوب', () {
      expect(ProgressEngine.isPassing(score: 6, threshold: 7), isFalse);
    });
    test('الدرجة أعلى من الحد → نجاح', () {
      expect(ProgressEngine.isPassing(score: 10, threshold: 7), isTrue);
    });
    test('صفر → رسوب', () {
      expect(ProgressEngine.isPassing(score: 0, threshold: 7), isFalse);
    });
  });

  group('evaluateAdvance — المقام المجمّد و>٥٠٪', () {
    test('مفيش نشطين → مفيش انتقال', () {
      const AdvanceEvaluation e = AdvanceEvaluation(
        passRate: 0,
        shouldAdvance: false,
      );
      final AdvanceEvaluation r = ProgressEngine.evaluateAdvance(
        activeAtPortionOpen: 0,
        passedCount: 0,
      );
      expect(r.shouldAdvance, e.shouldAdvance);
      expect(r.passRate, 0);
    });
    test('بالظبط ٥٠٪ → مايتنقلش (حصري)', () {
      final AdvanceEvaluation r = ProgressEngine.evaluateAdvance(
        activeAtPortionOpen: 4,
        passedCount: 2,
      );
      expect(r.passRate, 0.5);
      expect(r.shouldAdvance, isFalse);
    });
    test('أكتر من ٥٠٪ → ينتقل', () {
      final AdvanceEvaluation r = ProgressEngine.evaluateAdvance(
        activeAtPortionOpen: 5,
        passedCount: 3,
      );
      expect(r.passRate, closeTo(0.6, 1e-9));
      expect(r.shouldAdvance, isTrue);
    });
    test('أقل من ٥٠٪ → مايتنقلش', () {
      final AdvanceEvaluation r = ProgressEngine.evaluateAdvance(
        activeAtPortionOpen: 5,
        passedCount: 2,
      );
      expect(r.shouldAdvance, isFalse);
    });
    test('الكل عدّى → ينتقل', () {
      final AdvanceEvaluation r = ProgressEngine.evaluateAdvance(
        activeAtPortionOpen: 5,
        passedCount: 5,
      );
      expect(r.passRate, 1.0);
      expect(r.shouldAdvance, isTrue);
    });
    test('passedCount أكبر من المقام يتقصّ (حماية)', () {
      final AdvanceEvaluation r = ProgressEngine.evaluateAdvance(
        activeAtPortionOpen: 3,
        passedCount: 9,
      );
      expect(r.passRate, 1.0);
      expect(r.shouldAdvance, isTrue);
    });
  });

  group('nextLedgerState — انتقالات الدَيْن', () {
    test('assigned + نجاح → passed', () {
      expect(
        ProgressEngine.nextLedgerState(
          current: LedgerState.assigned,
          passed: true,
        ),
        LedgerState.passed,
      );
    });
    test('assigned + رسوب → failed_retry', () {
      expect(
        ProgressEngine.nextLedgerState(
          current: LedgerState.assigned,
          passed: false,
        ),
        LedgerState.failedRetry,
      );
    });
    test('failed_retry + رسوب → يفضل failed_retry', () {
      expect(
        ProgressEngine.nextLedgerState(
          current: LedgerState.failedRetry,
          passed: false,
        ),
        LedgerState.failedRetry,
      );
    });
    test('failed_retry + نجاح → passed', () {
      expect(
        ProgressEngine.nextLedgerState(
          current: LedgerState.failedRetry,
          passed: true,
        ),
        LedgerState.passed,
      );
    });
    test('passed يفضل passed حتى مع رسوب لاحق', () {
      expect(
        ProgressEngine.nextLedgerState(
          current: LedgerState.passed,
          passed: false,
        ),
        LedgerState.passed,
      );
    });
  });

  group('isStruggling', () {
    test('وصل للحد → تنبيه', () {
      expect(
        ProgressEngine.isStruggling(failedAttempts: 3, threshold: 3),
        isTrue,
      );
    });
    test('تحت الحد → مفيش تنبيه', () {
      expect(
        ProgressEngine.isStruggling(failedAttempts: 2, threshold: 3),
        isFalse,
      );
    });
  });

  group('LedgerState <-> db', () {
    test('dbValue', () {
      expect(LedgerState.failedRetry.dbValue, 'failed_retry');
      expect(LedgerState.passed.dbValue, 'passed');
      expect(LedgerState.assigned.dbValue, 'assigned');
    });
    test('fromDb', () {
      expect(LedgerState.fromDb('failed_retry'), LedgerState.failedRetry);
      expect(LedgerState.fromDb('passed'), LedgerState.passed);
      expect(LedgerState.fromDb('unknown'), LedgerState.assigned);
    });
  });
}
