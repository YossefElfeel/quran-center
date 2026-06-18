/// خطة الشهر للحلقة (المنهج + نظام التدريس + المقاطع).
class MonthlyPlan {
  const MonthlyPlan({
    this.curriculumPlan,
    this.teachingMethod,
    this.portionsRef,
  });

  factory MonthlyPlan.fromMap(Map<String, dynamic> map) => MonthlyPlan(
    curriculumPlan: map['curriculum_plan'] as String?,
    teachingMethod: map['teaching_method'] as String?,
    portionsRef: map['portions_ref'] as String?,
  );

  final String? curriculumPlan;
  final String? teachingMethod;
  final String? portionsRef;
}
