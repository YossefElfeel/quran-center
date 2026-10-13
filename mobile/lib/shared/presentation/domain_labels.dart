import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../features/admin_setup/domain/circle.dart';
import '../../features/admin_setup/domain/curriculum.dart';
import '../../features/documents/domain/certificate_kind.dart';
import '../../features/enrollment/domain/gender.dart';
import '../../features/session/domain/attendance_status.dart';
import '../../features/subscription/domain/subscription_status.dart';
import '../../features/supervisor_eval/domain/eval_criterion.dart';
import '../../features/supervisor_eval/domain/eval_selection.dart';

extension CurriculumTypeLabel on CurriculumType {
  String label(AppL10n l) => switch (this) {
    CurriculumType.quran => l.enumCurriculumTypequran,
    CurriculumType.arabicFoundation => l.enumCurriculumTypearabicFoundation,
  };
}

extension CircleStatusLabel on CircleStatus {
  String label(AppL10n l) => switch (this) {
    CircleStatus.forming => l.enumCircleStatusforming,
    CircleStatus.active => l.enumCircleStatusactive,
    CircleStatus.graduated => l.enumCircleStatusgraduated,
  };
}

extension AttendanceStatusLabel on AttendanceStatus {
  String label(AppL10n l) => switch (this) {
    AttendanceStatus.present => l.enumAttendanceStatuspresent,
    AttendanceStatus.absent => l.enumAttendanceStatusabsent,
    AttendanceStatus.absentExcused => l.enumAttendanceStatusabsentExcused,
    AttendanceStatus.late => l.enumAttendanceStatuslate,
  };
}

extension EvalSelectionLabel on EvalSelection {
  String label(AppL10n l) => switch (this) {
    EvalSelection.random => l.enumEvalSelectionrandom,
    EvalSelection.manual => l.enumEvalSelectionmanual,
  };
}

extension EvalCriterionLabel on EvalCriterion {
  String label(AppL10n l) => switch (this) {
    EvalCriterion.memorization => l.enumEvalCriterionmemorization,
    EvalCriterion.recitation => l.enumEvalCriterionrecitation,
    EvalCriterion.mushafReading => l.enumEvalCriterionmushafReading,
  };
}

extension SubscriptionStatusLabel on SubscriptionStatus {
  String label(AppL10n l) => switch (this) {
    SubscriptionStatus.active => l.enumSubscriptionStatusactive,
    SubscriptionStatus.grace => l.enumSubscriptionStatusgrace,
    SubscriptionStatus.overdue => l.enumSubscriptionStatusoverdue,
    SubscriptionStatus.inactive => l.enumSubscriptionStatusinactive,
  };
}

extension CertificateKindLabel on CertificateKind {
  String label(AppL10n l) => switch (this) {
    CertificateKind.juzAmma => l.enumCertificateKindjuzAmma,
    CertificateKind.half => l.enumCertificateKindhalf,
    CertificateKind.full => l.enumCertificateKindfull,
    CertificateKind.honor => l.enumCertificateKindhonor,
  };
}

extension GenderLabel on Gender {
  String label(AppL10n l) => switch (this) {
    Gender.male => l.enumGendermale,
    Gender.female => l.enumGenderfemale,
  };
}
