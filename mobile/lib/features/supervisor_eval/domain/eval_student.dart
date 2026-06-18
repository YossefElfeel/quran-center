/// طالب في شاشة تقييم المشرف — مع حالة الاختيار (للتقييم) والتقييم (اتقيّم).
class EvalStudent {
  const EvalStudent({
    required this.studentPersonId,
    required this.fullName,
    this.selected = false,
    this.scored = false,
  });

  final String studentPersonId;
  final String fullName;
  final bool selected;
  final bool scored;

  EvalStudent copyWith({bool? selected, bool? scored}) => EvalStudent(
    studentPersonId: studentPersonId,
    fullName: fullName,
    selected: selected ?? this.selected,
    scored: scored ?? this.scored,
  );
}
