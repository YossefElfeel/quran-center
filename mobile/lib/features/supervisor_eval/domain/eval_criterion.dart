/// معايير تقييم المشرف الـ٣ (كل معيار /١٠) — بتوافق enum eval_criterion في الـDB.
enum EvalCriterion {
  memorization,
  recitation,
  mushafReading;

  String get dbValue => switch (this) {
    EvalCriterion.memorization => 'memorization',
    EvalCriterion.recitation => 'recitation',
    EvalCriterion.mushafReading => 'mushaf_reading',
  };

  String get labelAr => switch (this) {
    EvalCriterion.memorization => 'الحفظ',
    EvalCriterion.recitation => 'التلاوة',
    EvalCriterion.mushafReading => 'القراءة من المصحف',
  };

  static EvalCriterion fromDb(String value) => switch (value) {
    'recitation' => EvalCriterion.recitation,
    'mushaf_reading' => EvalCriterion.mushafReading,
    _ => EvalCriterion.memorization,
  };
}
