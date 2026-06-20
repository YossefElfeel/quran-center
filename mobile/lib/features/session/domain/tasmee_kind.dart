import '../../../core/logging/logger.dart';

/// نوع التسميع: حفظ جديد أو مراجعة (بيوافق enum tasmee_kind في الداتابيز).
enum TasmeeKind {
  memorization,
  revision;

  String get dbValue => switch (this) {
    TasmeeKind.memorization => 'memorization',
    TasmeeKind.revision => 'revision',
  };

  static TasmeeKind fromDb(String value) {
    switch (value) {
      case 'memorization':
        return TasmeeKind.memorization;
      case 'revision':
        return TasmeeKind.revision;
    }
    AppLog.warn('Unknown tasmee kind from server: $value');
    return TasmeeKind.memorization;
  }
}
