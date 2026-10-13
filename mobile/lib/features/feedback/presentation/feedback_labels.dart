import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../data/feedback_repository.dart';
import '../domain/complaint.dart';

/// اسم تصنيف الشكوى للعرض (القيمة الخام لو التصنيف مش معروف).
String complaintCategoryLabel(String category, AppL10n l) => switch (category) {
  'academic' => l.fbkCategoryAcademic,
  'financial' => l.fbkCategoryFinancial,
  'behavioral' => l.fbkCategoryBehavioral,
  'privacy' => l.fbkCategoryPrivacy,
  'other' => l.fbkCategoryOther,
  _ => category,
};

extension ComplaintLabels on Complaint {
  String categoryLabel(AppL10n l) => complaintCategoryLabel(category, l);

  /// حالة الشكوى للعرض (القيمة الخام لو الحالة مش معروفة).
  String statusLabel(AppL10n l) => switch (status) {
    'open' => l.fbkComplaintStatusOpen,
    'answered' => l.fbkComplaintStatusAnswered,
    'reopened' => l.fbkComplaintStatusReopened,
    'closed' => l.fbkComplaintStatusClosed,
    _ => status,
  };
}

extension RateTeacherFailureLabel on RateTeacherFailure {
  String label(AppL10n l) => switch (this) {
    RateTeacherFailure.noTeacher => l.fbkRateErrorNoTeacher,
    RateTeacherFailure.alreadyRated => l.fbkRateErrorAlreadyRated,
  };
}
