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

  /// الـ embed بيرجع null لو الـ FK فاضي/الصف اتفلتر بالـ RLS/اتحذف — في الحالة
  /// دي بنرجّع null عشان الـ caller يفلتر الصف (مفيش طالب من غير id).
  static EnrolledStudent? fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? student =
        map['student'] as Map<String, dynamic>?;
    final String? studentPersonId = student?['id'] as String?;
    if (studentPersonId == null) return null;
    return EnrolledStudent(
      enrollmentId: map['id'] as String,
      studentPersonId: studentPersonId,
      name: (student?['full_name'] as String?) ?? '—',
      gender: Gender.fromDb(student?['gender'] as String?),
    );
  }
}
