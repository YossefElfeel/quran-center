import '../../enrollment/domain/gender.dart';

/// طفل في قايمة ولي الأمر.
class ChildSummary {
  const ChildSummary({
    required this.studentPersonId,
    required this.fullName,
    this.gender,
  });

  final String studentPersonId;
  final String fullName;
  final Gender? gender;
}
