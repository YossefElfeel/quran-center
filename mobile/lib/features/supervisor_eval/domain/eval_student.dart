import 'eval_criterion.dart';
import 'supervisor_eval_logic.dart';

/// طالب في شاشة تقييم المشرف — مع الاختيار وآخر درجات محفوظة.
class EvalStudent {
  const EvalStudent({
    required this.studentPersonId,
    required this.fullName,
    this.selected = false,
    this.scores = const <EvalCriterion, int>{},
    this.evaluatedAt,
  });

  final String studentPersonId;
  final String fullName;
  final bool selected;
  final Map<EvalCriterion, int> scores;
  final DateTime? evaluatedAt;

  bool get scored => scores.length == EvalCriterion.values.length;
  double get average => averageScore(scores.values);

  String get levelAr {
    final double value = average;
    if (value >= 9) return 'ممتاز';
    if (value >= 8) return 'جيد جدًا';
    if (value >= 7) return 'جيد';
    if (value >= 5) return 'مقبول';
    return 'يحتاج متابعة';
  }

  EvalStudent copyWith({
    bool? selected,
    Map<EvalCriterion, int>? scores,
    DateTime? evaluatedAt,
  }) => EvalStudent(
    studentPersonId: studentPersonId,
    fullName: fullName,
    selected: selected ?? this.selected,
    scores: scores ?? this.scores,
    evaluatedAt: evaluatedAt ?? this.evaluatedAt,
  );
}
