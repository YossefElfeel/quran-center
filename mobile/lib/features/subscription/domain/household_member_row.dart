/// فرد في أسرة (ولي أمر أو طالب).
class HouseholdMemberRow {
  const HouseholdMemberRow({required this.personName, required this.role});

  factory HouseholdMemberRow.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? p = map['person'] as Map<String, dynamic>?;
    return HouseholdMemberRow(
      personName: (p?['full_name'] as String?) ?? 'فرد',
      role: map['role'] as String,
    );
  }

  final String personName;
  final String role;

  String get roleAr => role == 'guardian' ? 'ولي أمر' : 'طالب';
}
