/// ملف المعلّم (سيرة + مؤهّلات + شهادات) — يشوفه/يعدّله المعلّم نفسه والأدمن.
class TeacherProfile {
  const TeacherProfile({
    this.cv,
    this.qualifications = const <String>[],
    this.certificates = const <String>[],
  });

  factory TeacherProfile.fromMap(Map<String, dynamic> map) => TeacherProfile(
    cv: map['cv'] as String?,
    qualifications: _list(map['qualifications']),
    certificates: _list(map['certificates']),
  );

  static List<String> _list(Object? v) => v is List
      ? v.map((Object? e) => e.toString()).toList()
      : const <String>[];

  final String? cv;
  final List<String> qualifications;
  final List<String> certificates;
}
