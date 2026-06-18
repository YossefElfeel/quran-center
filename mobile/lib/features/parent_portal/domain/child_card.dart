/// آخر تسميع للطالب (لكارت ولي الأمر).
class LatestTasmee {
  const LatestTasmee({
    required this.score,
    required this.passed,
    required this.portionName,
  });

  final int score;
  final bool passed;
  final String portionName;
}

/// كارت متابعة الطفل: الحلقة + آخر تسميع + ملخّص الحضور.
class ChildCard {
  const ChildCard({
    required this.present,
    required this.absent,
    required this.excused,
    required this.late,
    this.circleName,
    this.latestTasmee,
  });

  final String? circleName;
  final LatestTasmee? latestTasmee;
  final int present;
  final int absent;
  final int excused;
  final int late;

  bool get hasCircle => circleName != null;
}
