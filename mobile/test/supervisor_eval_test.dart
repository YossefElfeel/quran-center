import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/supervisor_eval/domain/eval_criterion.dart';
import 'package:quran_center/features/supervisor_eval/domain/eval_selection.dart';
import 'package:quran_center/features/supervisor_eval/domain/supervisor_eval_logic.dart';

void main() {
  const List<int> pool = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  group('pickRandom — اختيار عشوائي حتمي', () {
    test('نفس الـseed → نفس الاختيار', () {
      expect(pickRandom(pool, 3, seed: 42), pickRandom(pool, 3, seed: 42));
    });

    test('العدد صح ومن غير تكرار وكله من المصدر', () {
      final List<int> picked = pickRandom(pool, 4, seed: 7);
      expect(picked.length, 4);
      expect(picked.toSet().length, 4);
      expect(picked.every(pool.contains), isTrue);
    });

    test('count أكبر من المتاح → كل العناصر', () {
      expect(pickRandom(pool, 99, seed: 1).length, pool.length);
    });

    test('count صفر أو أقل → فاضي', () {
      expect(pickRandom(pool, 0, seed: 1), isEmpty);
      expect(pickRandom(pool, -5, seed: 1), isEmpty);
    });

    test('قايمة فاضية → فاضي', () {
      expect(pickRandom(<int>[], 3, seed: 1), isEmpty);
    });
  });

  group('averageScore', () {
    test('متوسّط ٣ معايير', () {
      expect(averageScore(<int>[8, 6, 10]), 8.0);
    });

    test('فاضي → صفر', () {
      expect(averageScore(<int>[]), 0);
    });
  });

  group('enums round-trip', () {
    test('EvalCriterion db ↔ enum', () {
      for (final EvalCriterion c in EvalCriterion.values) {
        expect(EvalCriterion.fromDb(c.dbValue), c);
      }
    });

    test('EvalSelection dbValue', () {
      expect(EvalSelection.random.dbValue, 'random');
      expect(EvalSelection.manual.dbValue, 'manual');
    });
  });
}
