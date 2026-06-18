/// نسبة نجاح حلقة على مقطعها الحالي (للوحة "محتاج انتباه").
class CirclePassRate {
  const CirclePassRate({
    required this.circleName,
    required this.activeAtOpen,
    required this.passedCount,
    this.passRate,
  });

  factory CirclePassRate.fromMap(Map<String, dynamic> map) => CirclePassRate(
    circleName: map['circle_name'] as String,
    activeAtOpen: (map['active_at_open'] as num?)?.toInt() ?? 0,
    passedCount: (map['passed_count'] as num?)?.toInt() ?? 0,
    passRate: (map['pass_rate'] as num?)?.toDouble(),
  );

  final String circleName;
  final int activeAtOpen;
  final int passedCount;

  /// null = الحلقة مفيهاش مقطع حالي (مش محسوبة).
  final double? passRate;

  /// محتاجة انتباه: عندها مقطع حالي ونسبة النجاح أقل من النص.
  bool get needsAttention => passRate != null && passRate! < 0.5;

  /// النسبة كنسبة مئوية (٠..١٠٠).
  int get percent => ((passRate ?? 0) * 100).round();
}
