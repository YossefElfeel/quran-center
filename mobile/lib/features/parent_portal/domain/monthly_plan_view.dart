/// خطة الشهر للحلقة (اللي ولي الأمر بيشوفها لطفله).
class MonthlyPlanView {
  const MonthlyPlanView({
    this.curriculumPlan,
    this.teachingMethod,
    this.portionsRef,
  });

  factory MonthlyPlanView.fromMap(Map<String, dynamic> map) => MonthlyPlanView(
    curriculumPlan: map['curriculum_plan'] as String?,
    teachingMethod: map['teaching_method'] as String?,
    portionsRef: map['portions_ref'] as String?,
  );

  final String? curriculumPlan;
  final String? teachingMethod;
  final String? portionsRef;

  bool get isEmpty =>
      (curriculumPlan == null || curriculumPlan!.trim().isEmpty) &&
      (teachingMethod == null || teachingMethod!.trim().isEmpty) &&
      (portionsRef == null || portionsRef!.trim().isEmpty);
}
