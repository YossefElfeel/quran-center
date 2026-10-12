import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/excuse/domain/pending_excuse.dart';
import 'package:quran_center/features/feedback/domain/complaint.dart';
import 'package:quran_center/features/supervisor_eval/domain/eval_criterion.dart';
import 'package:quran_center/features/supervisor_eval/domain/eval_student.dart';

void main() {
  group('complaint metadata', () {
    test('exposes a stable short reference and response date', () {
      final Complaint complaint = Complaint.fromMap(<String, dynamic>{
        'id': '12345678-abcd-4000-8000-123456789abc',
        'category': 'academic',
        'body': 'محتوى الشكوى',
        'status': 'answered',
        'created_at': '2026-09-20T10:00:00Z',
        'manager_response': 'تمت المتابعة',
        'responded_at': '2026-09-20T11:00:00Z',
      });

      expect(complaint.referenceNumber, '12345678');
      expect(complaint.isAnswered, isTrue);
      expect(complaint.respondedAt, DateTime.utc(2026, 9, 20, 11));
    });
  });

  group('excuse decision state', () {
    test('copyWith preserves details and exposes the final decision', () {
      final PendingExcuse pending = PendingExcuse.fromMap(<String, dynamic>{
        'id': 'excuse-1',
        'enrollment_id': 'enrollment-1',
        'session_id': 'session-1',
        'reason': 'سفر مع العائلة',
        'status': 'pending',
        'created_at': '2026-09-20T10:00:00Z',
        'enrollment': <String, dynamic>{
          'student': <String, dynamic>{'full_name': 'طالب تجريبي'},
          'circle': <String, dynamic>{'name': 'حلقة تجريبية'},
        },
      });

      final PendingExcuse approved = pending.copyWith(
        status: 'approved',
        decidedAt: DateTime.utc(2026, 9, 20, 11),
      );

      expect(approved.isPending, isFalse);
      expect(approved.isApproved, isTrue);
      expect(approved.reason, pending.reason);
      expect(approved.decidedAt, DateTime.utc(2026, 9, 20, 11));
    });
  });

  group('supervisor evaluation result', () {
    test('retains criterion scores and derives average and level', () {
      const EvalStudent student = EvalStudent(
        studentPersonId: 'student-1',
        fullName: 'طالب تجريبي',
        scores: <EvalCriterion, int>{
          EvalCriterion.memorization: 9,
          EvalCriterion.recitation: 8,
          EvalCriterion.mushafReading: 7,
        },
      );

      expect(student.scored, isTrue);
      expect(student.average, 8);
      expect(student.levelAr, 'جيد جدًا');
    });

    test('marks an incomplete evaluation as not scored', () {
      const EvalStudent student = EvalStudent(
        studentPersonId: 'student-1',
        fullName: 'طالب تجريبي',
        scores: <EvalCriterion, int>{EvalCriterion.memorization: 10},
      );

      expect(student.scored, isFalse);
    });
  });
}
