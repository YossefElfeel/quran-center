import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../domain/household_member_row.dart';

extension HouseholdMemberRowLabel on HouseholdMemberRow {
  String roleLabel(AppL10n l) =>
      role == 'guardian' ? l.subsRoleGuardian : l.subsRoleStudent;
}
