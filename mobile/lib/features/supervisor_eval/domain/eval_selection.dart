/// طريقة اختيار الطلبة للتقييم: عشوائي بالنظام أو يدوي بالمشرف.
enum EvalSelection {
  random,
  manual;

  String get dbValue => switch (this) {
    EvalSelection.random => 'random',
    EvalSelection.manual => 'manual',
  };
}
