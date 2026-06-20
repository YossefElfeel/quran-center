import '../../progress_engine/domain/ledger_state.dart';

/// حالة طالب على المقطع الحالي للحلقة (تفصيل لوحة الانتباه).
class CircleRosterScore {
  const CircleRosterScore({required this.studentName, this.state});

  final String studentName;

  /// null = لسه ماتسمّعش على المقطع الحالي.
  final LedgerState? state;
}

/// تفصيل درجات حلقة: المقطع الحالي + حالة كل طالب عليه.
class CircleScores {
  const CircleScores({required this.students, this.portionName});

  /// null = الحلقة مفيهاش مقطع حالي.
  final String? portionName;
  final List<CircleRosterScore> students;

  int get passed => students
      .where((CircleRosterScore s) => s.state == LedgerState.passed)
      .length;
  int get failed => students
      .where((CircleRosterScore s) => s.state == LedgerState.failedRetry)
      .length;
}
