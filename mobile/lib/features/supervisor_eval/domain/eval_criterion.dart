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

  static EvalCriterion fromDb(String value) => switch (value) {
    'recitation' => EvalCriterion.recitation,
    'mushaf_reading' => EvalCriterion.mushafReading,
    _ => EvalCriterion.memorization,
  };
}
