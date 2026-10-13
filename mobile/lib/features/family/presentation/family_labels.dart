import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../domain/guardian_link_row.dart';

/// تسمية صلة القرابة (father / mother / غير كده) للعرض.
String guardianRelationLabel(String relation, AppL10n l) => switch (relation) {
  'father' => l.famRelationFather,
  'mother' => l.famRelationMother,
  _ => l.roleParent,
};

extension GuardianLinkRowLabel on GuardianLinkRow {
  String relationLabel(AppL10n l) => guardianRelationLabel(relation, l);
}
