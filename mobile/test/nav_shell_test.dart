import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/app/shell/nav_destinations.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

/// يلفّ الـ widget في MaterialApp عربي (RTL + مفاتيح الترجمة) مع عرض هاتف.
Widget _wrap(Widget child, {Size size = const Size(390, 844)}) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(size: size),
    child: Scaffold(body: child),
  ),
);

/// يجيب AppL10n من غير ما نرسم شجرة كاملة — Builder صغير يلتقط الـ context.
Future<AppL10n> _l10n(WidgetTester tester) async {
  late AppL10n captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Builder(
        builder: (BuildContext context) {
          captured = AppL10n.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  // ---------------------------------------------------------------------------
  // وحدات: منطق التنقّل المتكيّف مع الدور (destinationsForRoles / primaryFor).
  // ملاحظة: AppShell نفسه بيراقب providers مدعومة بـ Drift/شبكة (إشعارات،
  // اتصال، onboarding، هوية) وبيطلب StatefulNavigationShell حيّ — فممنوع نرسمه
  // في widget test (قاعدة الريبو: ممنوع فتح Drift في اختبارات الـ widget).
  // فبنختبر نفس الدالة النقيّة اللي AppShell بيبني منها وجهاته، وبنرسم
  // NavigationBar مباشرة من ناتجها (نفس منطق فرع الهاتف في AppShell).
  // ---------------------------------------------------------------------------
  group('destinationsForRoles — عدد ثابت', () {
    testWidgets('دايمًا ٤ وجهات (مهما كان الدور)', (WidgetTester tester) async {
      final AppL10n l = await _l10n(tester);
      for (final List<String> roles in <List<String>>[
        <String>[],
        <String>['teacher'],
        <String>['parent'],
        <String>['supervisor'],
        <String>['admin'],
        <String>['super_admin'],
        <String>['teacher', 'admin'],
        <String>['student'], // دور غير معروف → fallback
      ]) {
        expect(
          destinationsForRoles(l, roles).length,
          4,
          reason: 'عدد الفروع ثابت بغضّ النظر عن الأدوار: $roles',
        );
      }
    });

    testWidgets('أول وجهة دايمًا الرئيسية وآخر وجهة "المزيد"', (
      WidgetTester tester,
    ) async {
      final AppL10n l = await _l10n(tester);
      final List<AppDestination> d = destinationsForRoles(l, <String>['admin']);
      expect(d.first.label, l.tabHome);
      expect(d[2].label, l.notificationsTooltip); // slot الإشعارات (index 2)
      expect(d.last.label, l.tabMore);
    });

    testWidgets('الوجهة الأساسية (slot 1) = نفس primaryDestinationFor', (
      WidgetTester tester,
    ) async {
      final AppL10n l = await _l10n(tester);
      for (final List<String> roles in <List<String>>[
        <String>['teacher'],
        <String>['parent'],
        <String>['supervisor'],
        <String>[],
      ]) {
        expect(
          destinationsForRoles(l, roles)[1].label,
          primaryDestinationFor(l, roles).label,
        );
      }
    });
  });

  group('primaryDestinationFor — التبويب الأساسي حسب الدور', () {
    testWidgets('معلّم → حلقاتي', (WidgetTester tester) async {
      final AppL10n l = await _l10n(tester);
      final AppDestination p = primaryDestinationFor(l, <String>['teacher']);
      expect(p.label, l.navMyCircles);
      expect(p.icon, Icons.menu_book_outlined);
      expect(p.selectedIcon, Icons.menu_book);
    });

    testWidgets('ولي أمر → أبنائي', (WidgetTester tester) async {
      final AppL10n l = await _l10n(tester);
      final AppDestination p = primaryDestinationFor(l, <String>['parent']);
      expect(p.label, l.navMyChildren);
      expect(p.icon, Icons.child_care_outlined);
    });

    testWidgets('مشرف/أدمن/سوبر-أدمن → المراجعات', (WidgetTester tester) async {
      final AppL10n l = await _l10n(tester);
      for (final String role in <String>[
        'supervisor',
        'admin',
        'super_admin',
      ]) {
        final AppDestination p = primaryDestinationFor(l, <String>[role]);
        expect(p.label, l.tabReviews, reason: 'الدور: $role');
        expect(p.icon, Icons.fact_check_outlined, reason: 'الدور: $role');
      }
    });

    testWidgets('بدون دور / لسه بيحمّل (قائمة فاضية) → لوحة الشرف (fallback)', (
      WidgetTester tester,
    ) async {
      final AppL10n l = await _l10n(tester);
      // ما بيرميش استثناء على القائمة الفاضية، وبيرجّع التبويب الاحتياطي.
      final AppDestination p = primaryDestinationFor(l, const <String>[]);
      expect(p.label, l.navHonorBoard);
      expect(p.icon, Icons.military_tech_outlined);
    });

    testWidgets('دور غير معروف لوحده → نفس fallback لوحة الشرف', (
      WidgetTester tester,
    ) async {
      final AppL10n l = await _l10n(tester);
      final AppDestination p = primaryDestinationFor(l, <String>['student']);
      expect(p.label, l.navHonorBoard);
    });

    testWidgets('أولوية الأدوار: معلّم يكسب على أدمن لو الاتنين موجودين', (
      WidgetTester tester,
    ) async {
      final AppL10n l = await _l10n(tester);
      expect(
        primaryDestinationFor(l, <String>['admin', 'teacher']).label,
        l.navMyCircles,
      );
      // والترتيب العكسي برضه (الأولوية مش معتمدة على ترتيب القائمة).
      expect(
        primaryDestinationFor(l, <String>['teacher', 'admin']).label,
        l.navMyCircles,
      );
    });

    testWidgets('أولوية: ولي أمر يكسب على مشرف', (WidgetTester tester) async {
      final AppL10n l = await _l10n(tester);
      expect(
        primaryDestinationFor(l, <String>['supervisor', 'parent']).label,
        l.navMyChildren,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Widget: نرسم NavigationBar من نفس ناتج destinationsForRoles (عرض هاتف)
  // من غير ما نرسم AppShell الكامل (اللي بيلمس Drift/شبكة). ده بيتحقق إن
  // عدد الوجهات الظاهرة في الشريط = عدد الفروع الثابت.
  // ---------------------------------------------------------------------------
  group('NavigationBar (عرض هاتف) — يرسم الوجهات المتوقّعة', () {
    testWidgets('٤ وجهات ظاهرة + التبويب الأساسي للمعلّم = حلقاتي', (
      WidgetTester tester,
    ) async {
      final AppL10n l = await _l10n(tester);
      final List<AppDestination> destinations = destinationsForRoles(
        l,
        <String>['teacher'],
      );

      await tester.pumpWidget(
        _wrap(
          Scaffold(
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (int _) {},
              destinations: <NavigationDestination>[
                for (final AppDestination d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      // التسمية الأساسية للمعلّم تظهر في الشريط.
      expect(find.text(l.navMyCircles), findsOneWidget);
      expect(find.text(l.tabHome), findsOneWidget);
    });

    testWidgets('التبويب الأساسي لولي الأمر = أبنائي يظهر في الشريط', (
      WidgetTester tester,
    ) async {
      final AppL10n l = await _l10n(tester);
      final List<AppDestination> destinations = destinationsForRoles(
        l,
        <String>['parent'],
      );

      await tester.pumpWidget(
        _wrap(
          Scaffold(
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (int _) {},
              destinations: <NavigationDestination>[
                for (final AppDestination d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.text(l.navMyChildren), findsOneWidget);
    });
  });
}
