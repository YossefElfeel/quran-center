import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../app/router/routes.dart';

/// تصنيفات الميزات في مركز "المزيد".
enum FeatureCategory { admin, supervisor, teacher, parent, general }

String categoryLabel(AppL10n l, FeatureCategory c) {
  switch (c) {
    case FeatureCategory.admin:
      return l.catAdmin;
    case FeatureCategory.supervisor:
      return l.catSupervisor;
    case FeatureCategory.teacher:
      return l.catTeacher;
    case FeatureCategory.parent:
      return l.catParent;
    case FeatureCategory.general:
      return l.catGeneral;
  }
}

/// عنصر ميزة — مصدر واحد لكل ميزات التطبيق (المزيد + الإجراءات السريعة + المفضّلة).
class FeatureItem {
  const FeatureItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.roles,
    required this.category,
  });

  /// مُعرّف ثابت للمفضّلة = المسار.
  String get id => route;
  final String Function(AppL10n l) label;
  final IconData icon;
  final String route;

  /// أدوار مسموح لها؛ فاضية = الكل.
  final List<String> roles;
  final FeatureCategory category;

  bool visibleTo(List<String> userRoles) =>
      roles.isEmpty || roles.any(userRoles.contains);
}

const List<String> _admins = <String>['admin', 'super_admin'];
const List<String> _supervisors = <String>[
  'supervisor',
  'admin',
  'super_admin',
];

/// كل ميزات التطبيق (نظير لأزرار الشاشة الرئيسية القديمة، بترتيب منطقي).
final List<FeatureItem> kFeatureCatalog = <FeatureItem>[
  // الإدارة
  FeatureItem(
    label: (AppL10n l) => l.navCurriculaCircles,
    icon: Icons.account_tree,
    route: Routes.adminCurricula,
    roles: _admins,
    category: FeatureCategory.admin,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navWaitingList,
    icon: Icons.how_to_reg,
    route: Routes.adminWaiting,
    roles: _admins,
    category: FeatureCategory.admin,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navSubscriptions,
    icon: Icons.payments,
    route: Routes.adminSubscriptions,
    roles: _admins,
    category: FeatureCategory.admin,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navGuardianLinks,
    icon: Icons.link,
    route: Routes.adminGuardians,
    roles: _admins,
    category: FeatureCategory.admin,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navInviteUser,
    icon: Icons.person_add,
    route: Routes.adminInviteUser,
    roles: _admins,
    category: FeatureCategory.admin,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navComplaintsInbox,
    icon: Icons.inbox,
    route: Routes.complaintsInbox,
    roles: _admins,
    category: FeatureCategory.admin,
  ),
  // الإشراف
  FeatureItem(
    label: (AppL10n l) => l.navEvalCircles,
    icon: Icons.fact_check,
    route: Routes.supervisorEval,
    roles: _supervisors,
    category: FeatureCategory.supervisor,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navExcuses,
    icon: Icons.event_busy,
    route: Routes.supervisorExcuses,
    roles: _supervisors,
    category: FeatureCategory.supervisor,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navAttention,
    icon: Icons.warning_amber,
    route: Routes.supervisorAttention,
    roles: _supervisors,
    category: FeatureCategory.supervisor,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navTeacherDev,
    icon: Icons.school,
    route: Routes.supervisorDevApproval,
    roles: _supervisors,
    category: FeatureCategory.supervisor,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navMonthlyEvalApproval,
    icon: Icons.assignment_turned_in,
    route: Routes.supervisorMonthlyEval,
    roles: _supervisors,
    category: FeatureCategory.supervisor,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navIssueCertificates,
    icon: Icons.workspace_premium,
    route: Routes.issueCertificate,
    roles: _supervisors,
    category: FeatureCategory.supervisor,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navTeacherRatings,
    icon: Icons.star_half,
    route: Routes.teacherRatings,
    roles: _supervisors,
    category: FeatureCategory.supervisor,
  ),
  // المعلّم
  FeatureItem(
    label: (AppL10n l) => l.navMyCircles,
    icon: Icons.menu_book,
    route: Routes.teacherCircles,
    roles: const <String>['teacher'],
    category: FeatureCategory.teacher,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navMyProfileDev,
    icon: Icons.trending_up,
    route: Routes.teacherDevelopment,
    roles: const <String>['teacher'],
    category: FeatureCategory.teacher,
  ),
  // ولي الأمر
  FeatureItem(
    label: (AppL10n l) => l.navMyChildren,
    icon: Icons.child_care,
    route: Routes.parentChildren,
    roles: const <String>['parent'],
    category: FeatureCategory.parent,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navMyComplaints,
    icon: Icons.support_agent,
    route: Routes.complaintsMine,
    roles: const <String>['parent'],
    category: FeatureCategory.parent,
  ),
  // عام
  FeatureItem(
    label: (AppL10n l) => l.navCompetitions,
    icon: Icons.emoji_events,
    route: Routes.competitions,
    roles: const <String>['admin', 'super_admin', 'supervisor', 'teacher'],
    category: FeatureCategory.general,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navHonorBoard,
    icon: Icons.military_tech,
    route: Routes.honorBoard,
    roles: const <String>[],
    category: FeatureCategory.general,
  ),
  FeatureItem(
    label: (AppL10n l) => l.navCourses,
    icon: Icons.ondemand_video,
    route: Routes.courses,
    roles: const <String>[],
    category: FeatureCategory.general,
  ),
];

/// الميزات المرئية لمجموعة أدوار.
List<FeatureItem> featuresFor(List<String> roles) =>
    kFeatureCatalog.where((FeatureItem f) => f.visibleTo(roles)).toList();
