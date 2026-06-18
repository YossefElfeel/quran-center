/// طريقة اختيار الطلبة للتقييم: عشوائي بالنظام أو يدوي بالمشرف.
enum EvalSelection {
  random,
  manual;

  String get dbValue => switch (this) {
    EvalSelection.random => 'random',
    EvalSelection.manual => 'manual',
  };

  String get labelAr => switch (this) {
    EvalSelection.random => 'عشوائي',
    EvalSelection.manual => 'يدوي',
  };
}
