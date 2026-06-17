import '../../enrollment/domain/gender.dart';

/// متقدّم في قائمة الانتظار (waiting_list + بيانات الـ person والمستوى عبر join).
class WaitingApplicant {
  const WaitingApplicant({
    required this.waitingId,
    required this.personId,
    required this.name,
    required this.levelId,
    required this.levelName,
    this.gender,
  });

  final String waitingId;
  final String personId;
  final String name;
  final String levelId;
  final String levelName;
  final Gender? gender;

  factory WaitingApplicant.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> student = map['student'] as Map<String, dynamic>;
    final Map<String, dynamic>? level = map['level'] as Map<String, dynamic>?;
    return WaitingApplicant(
      waitingId: map['id'] as String,
      personId: student['id'] as String,
      name: student['full_name'] as String,
      gender: Gender.fromDb(student['gender'] as String?),
      levelId: map['level_id'] as String,
      levelName: level?['name'] as String? ?? '—',
    );
  }
}
