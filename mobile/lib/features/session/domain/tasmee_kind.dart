/// نوع التسميع: حفظ جديد أو مراجعة (بيوافق enum tasmee_kind في الداتابيز).
enum TasmeeKind {
  memorization,
  revision;

  String get dbValue => switch (this) {
    TasmeeKind.memorization => 'memorization',
    TasmeeKind.revision => 'revision',
  };

  static TasmeeKind fromDb(String value) => switch (value) {
    'revision' => TasmeeKind.revision,
    _ => TasmeeKind.memorization,
  };
}
