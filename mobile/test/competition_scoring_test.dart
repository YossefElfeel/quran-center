import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/competition/domain/competition_scoring.dart';

void main() {
  group('averageScore', () {
    test('فاضي → صفر', () {
      expect(averageScore(<double>[]), 0);
    });
    test('متوسّط القيم', () {
      expect(averageScore(<double>[80, 90, 100]), 90);
    });
  });

  group('rankApplicants', () {
    test('بيرتّب بالمتوسّط تنازليًا', () {
      final List<ApplicantResult> r = rankApplicants(<String, List<double>>{
        'a': <double>[70, 70],
        'b': <double>[90, 90],
        'c': <double>[80, 80],
      });
      expect(r.map((ApplicantResult x) => x.applicationId).toList(), <String>[
        'b',
        'c',
        'a',
      ]);
    });

    test('كسر التعادل بأعلى درجة مفردة', () {
      // نفس المتوسّط (80) لكن b عنده درجة مفردة أعلى (95).
      final List<ApplicantResult> r = rankApplicants(<String, List<double>>{
        'a': <double>[80, 80],
        'b': <double>[95, 65],
      });
      expect(r.first.applicationId, 'b');
    });

    test('تعادل تام → ثبات بالمعرّف', () {
      final List<ApplicantResult> r = rankApplicants(<String, List<double>>{
        'z': <double>[80],
        'a': <double>[80],
      });
      expect(r.first.applicationId, 'a');
    });
  });
}
