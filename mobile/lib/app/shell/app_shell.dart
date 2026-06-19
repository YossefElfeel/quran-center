import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/network/network_status.dart';
import '../../features/notifications/presentation/controllers/notifications_controller.dart';
import '../../shared/widgets/app_inline_banner.dart';
import 'nav_destinations.dart';

/// قشرة التطبيق — تحمل فروع التنقّل + شريط سفلي (موبايل) أو ريل (تابلت).
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const double _railBreakpoint = 760;

  void _onSelect(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      // إعادة النقر على التبويب الحالي ترجّع لجذره.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final List<String> roles =
        ref.watch(currentRolesProvider).asData?.value ?? const <String>[];
    final int unread = ref.watch(unreadCountProvider).asData?.value ?? 0;
    final List<AppDestination> destinations = destinationsForRoles(l, roles);
    final int current = navigationShell.currentIndex;
    final bool online =
        ref.watch(connectivityOnlineProvider).asData?.value ?? true;

    Widget badgeWrap(Widget icon, int index) {
      // شارة العدّاد على تبويب الإشعارات (index 2).
      if (index != 2 || unread == 0) return icon;
      return Badge.count(count: unread, child: icon);
    }

    final Widget shellBody = Column(
      children: <Widget>[
        if (!online)
          AppInlineBanner(message: l.noConnection, kind: AppBannerKind.offline),
        Expanded(child: navigationShell),
      ],
    );

    final bool wide = MediaQuery.sizeOf(context).width >= _railBreakpoint;

    if (wide) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: current,
              onDestinationSelected: _onSelect,
              labelType: NavigationRailLabelType.all,
              destinations: <NavigationRailDestination>[
                for (int i = 0; i < destinations.length; i++)
                  NavigationRailDestination(
                    icon: badgeWrap(Icon(destinations[i].icon), i),
                    selectedIcon: badgeWrap(
                      Icon(destinations[i].selectedIcon),
                      i,
                    ),
                    label: Text(destinations[i].label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shellBody),
          ],
        ),
      );
    }

    return Scaffold(
      body: shellBody,
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: _onSelect,
        destinations: <NavigationDestination>[
          for (int i = 0; i < destinations.length; i++)
            NavigationDestination(
              icon: badgeWrap(Icon(destinations[i].icon), i),
              selectedIcon: badgeWrap(Icon(destinations[i].selectedIcon), i),
              label: destinations[i].label,
            ),
        ],
      ),
    );
  }
}
