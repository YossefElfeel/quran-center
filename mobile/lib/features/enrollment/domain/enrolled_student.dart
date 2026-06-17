import 'gender.dart';

/// طالب مسجّل في حلقة (من enrollment + بيانات الـ person عبر join).
class EnrolledStudent {
  const EnrolledStudent({
    required this.enrollmentId,
    required this.studentPersonId,
    required this.name,
    this.gender,
  });

  final String enrollmentId;
  final String studentPersonId;
  final String name;
  final Gender? gender;

  factory EnrolledStudent.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> student = map['student'] as Map<String, dynamic>;
    return EnrolledStudent(
      enrollmentId: map['id'] as String,
      studentPersonId: student['id'] as String,
      name: student['full_name'] as String,
      gender: Gender.fromDb(student['gender'] as String?),
    );
  }
}
