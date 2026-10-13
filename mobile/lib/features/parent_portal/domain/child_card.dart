/// آخر تسميع للطالب (لكارت ولي الأمر).
class LatestTasmee {
  const LatestTasmee({
    required this.score,
    required this.passed,
    required this.portionName,
    this.date,
  });

  final int score;
  final bool passed;
  final String portionName;
  final DateTime? date;
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
    this.isGirl = false,
    this.currentPortion,
  });

  final String? circleName;
  final String? currentPortion;
  final LatestTasmee? latestTasmee;
  final int present;
  final int absent;
  final int excused;
  final int late;

  /// بنت؟ (لإظهار بوابة موافقة الوسائط — الأولاد عادي).
  final bool isGirl;

  bool get hasCircle => circleName != null;
}
