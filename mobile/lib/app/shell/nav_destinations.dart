import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

/// وجهة في شريط التنقّل (أيقونة عادية/محدّدة + تسمية).
class AppDestination {
  const AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const List<String> _supervisorRoles = <String>[
  'supervisor',
  'admin',
  'super_admin',
];

/// التبويب الأساسي (slot 1) حسب أولوية الدور — يحدّد التسمية والأيقونة.
AppDestination primaryDestinationFor(AppL10n l, List<String> roles) {
  if (roles.contains('teacher')) {
    return AppDestination(
      label: l.navMyCircles,
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    );
  }
  if (roles.contains('parent')) {
    return AppDestination(
      label: l.navMyChildren,
      icon: Icons.child_care_outlined,
      selectedIcon: Icons.child_care,
    );
  }
  if (roles.any(_supervisorRoles.contains)) {
    return AppDestination(
      label: l.tabReviews,
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
    );
  }
  return AppDestination(
    label: l.navHonorBoard,
    icon: Icons.military_tech_outlined,
    selectedIcon: Icons.military_tech,
  );
}

/// الوجهات الأربع الثابتة (الترتيب يطابق فروع الـ shell).
List<AppDestination> destinationsForRoles(AppL10n l, List<String> roles) {
  return <AppDestination>[
    AppDestination(
      label: l.tabHome,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    primaryDestinationFor(l, roles),
    AppDestination(
      label: l.notificationsTooltip,
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
    ),
    AppDestination(
      label: l.tabMore,
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view,
    ),
  ];
}
