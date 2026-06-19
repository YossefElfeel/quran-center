import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/app/router/routes.dart';
import 'package:quran_center/app/shell/nav_destinations.dart';
import 'package:quran_center/features/more/feature_catalog.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:quran_center/shared/theme/theme_mode_provider.dart';

void main() {
  group('feature catalog role gating', () {
    test('teacher sees my-circles, not admin curricula', () {
      final List<FeatureItem> f = featuresFor(<String>['teacher']);
      expect(
        f.any((FeatureItem x) => x.route == Routes.teacherCircles),
        isTrue,
      );
      expect(
        f.any((FeatureItem x) => x.route == Routes.adminCurricula),
        isFalse,
      );
    });

    test('admin sees curricula + subscriptions', () {
      final List<FeatureItem> f = featuresFor(<String>['admin']);
      expect(
        f.any((FeatureItem x) => x.route == Routes.adminCurricula),
        isTrue,
      );
      expect(
        f.any((FeatureItem x) => x.route == Routes.adminSubscriptions),
        isTrue,
      );
    });

    test('everyone sees honor board + courses regardless of role', () {
      for (final List<String> roles in <List<String>>[
        <String>[],
        <String>['teacher'],
        <String>['parent'],
      ]) {
        final List<FeatureItem> f = featuresFor(roles);
        expect(f.any((FeatureItem x) => x.route == Routes.honorBoard), isTrue);
        expect(f.any((FeatureItem x) => x.route == Routes.courses), isTrue);
      }
    });
  });

  group('theme mode mapping', () {
    test('amoled maps to dark ThemeMode', () {
      expect(themeModeFor(AppThemeChoice.amoled), ThemeMode.dark);
      expect(themeModeFor(AppThemeChoice.dark), ThemeMode.dark);
      expect(themeModeFor(AppThemeChoice.light), ThemeMode.light);
      expect(themeModeFor(AppThemeChoice.system), ThemeMode.system);
    });
  });

  testWidgets('role-adaptive primary nav destination', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            final AppL10n l = AppL10n.of(context);
            // أربع وجهات ثابتة دائمًا.
            expect(destinationsForRoles(l, <String>['teacher']).length, 4);
            // التبويب الأساسي يتغيّر حسب الدور (بالأولوية).
            expect(
              primaryDestinationFor(l, <String>['teacher']).label,
              l.navMyCircles,
            );
            expect(
              primaryDestinationFor(l, <String>['parent']).label,
              l.navMyChildren,
            );
            expect(
              primaryDestinationFor(l, <String>['supervisor']).label,
              l.tabReviews,
            );
            expect(
              primaryDestinationFor(l, <String>['admin']).label,
              l.tabReviews,
            );
            // معلّم له أولوية على مشرف لو عنده الدورين.
            expect(
              primaryDestinationFor(l, <String>['teacher', 'admin']).label,
              l.navMyCircles,
            );
            // بدون دور → لوحة الشرف.
            expect(primaryDestinationFor(l, <String>[]).label, l.navHonorBoard);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
