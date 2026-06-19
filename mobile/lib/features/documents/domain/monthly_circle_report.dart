/// بيانات تقرير الحلقة الشهري (للعرض/الطباعة فقط) — نموذج نقي.
class MonthlyCircleReport {
  const MonthlyCircleReport({
    required this.circleName,
    required this.monthLabel,
    required this.activeStudents,
    required this.avgAttendanceRate,
    required this.passRate,
    required this.topStudentName,
    required this.portions,
  });

  /// اسم الحلقة.
  final String circleName;

  /// الشهر بصيغة عرض (مثلاً "مايو ٢٠٢٦").
  final String monthLabel;

  /// عدد الطلبة النشطين في الحلقة.
  final int activeStudents;

  /// متوسّط الحضور للشهر (٠..١).
  final double avgAttendanceRate;

  /// نسبة نجاح التسميع للحلقة في الشهر (٠..١).
  final double passRate;

  /// اسم المتفوّق (فاضي لو مفيش).
  final String topStudentName;

  /// ملخّص تقدّم المقاطع خلال الشهر.
  final List<MonthlyCirclePortionProgress> portions;
}

/// صف تقدّم مقطع واحد في تقرير الحلقة الشهري.
class MonthlyCirclePortionProgress {
  const MonthlyCirclePortionProgress({
    required this.label,
    required this.passed,
    required this.total,
  });

  /// اسم المقطع.
  final String label;

  /// عدد التسميعات الناجحة للمقطع.
  final int passed;

  /// إجمالي محاولات التسميع للمقطع.
  final int total;
}
