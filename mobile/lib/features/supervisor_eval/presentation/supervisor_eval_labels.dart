import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../domain/eval_student.dart';

extension EvalLevelLabel on EvalLevel {
  String label(AppL10n l) => switch (this) {
    EvalLevel.excellent => l.supLevelExcellent,
    EvalLevel.veryGood => l.supLevelVeryGood,
    EvalLevel.good => l.supLevelGood,
    EvalLevel.acceptable => l.supLevelAcceptable,
    EvalLevel.needsFollowUp => l.supLevelNeedsFollowUp,
  };
}
