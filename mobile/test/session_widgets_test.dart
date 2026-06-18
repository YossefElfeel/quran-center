import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/session/presentation/widgets/debt_strip.dart';
import 'package:quran_center/features/session/presentation/widgets/score_pad.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:quran_center/shared/widgets/app_error_view.dart';

/// يلفّ الـ widget في MaterialApp عربي (RTL + مفاتيح الترجمة).
Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  home: Scaffold(body: child),
);

void _noop(int _) {}

void main() {
  group('ScorePad', () {
    testWidgets('بيعرض ١١ خلية (٠–١٠) وبيرجّع الدرجة عند اللمس', (
      WidgetTester tester,
    ) async {
      int? picked;
      await tester.pumpWidget(
        _wrap(
          ScorePad(
            selected: null,
            threshold: 7,
            onSelected: (int v) => picked = v,
          ),
        ),
      );

      expect(find.byType(InkWell), findsNWidgets(11)); // ٠..١٠
      await tester.tap(find.text('٨'));
      expect(picked, 8);
    });

    testWidgets('الدرجة المختارة نصّها أبيض (متلوّنة)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ScorePad(selected: 9, threshold: 7, onSelected: _noop)),
      );

      final Text nine = tester.widget<Text>(find.text('٩'));
      expect(nine.style?.color, Colors.white);
    });
  });

  group('DebtStrip', () {
    testWidgets('بيعرض عدّوا/الإجمالي + الدَيْن بأرقام عربية', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const DebtStrip(passedCount: 3, debtCount: 2, total: 5)),
      );

      expect(find.textContaining('٣/٥'), findsOneWidget);
      expect(find.textContaining('٢'), findsWidgets);
    });
  });

  group('AppErrorView', () {
    testWidgets('زر الإعادة بياخد النص الافتراضي "إعادة المحاولة" من الترجمة', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(AppErrorView(message: 'حصل خطأ', onRetry: () {})),
      );

      expect(find.text('حصل خطأ'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });

    testWidgets('من غير onRetry مفيش زر إعادة', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const AppErrorView(message: 'حصل خطأ')));

      expect(find.text('إعادة المحاولة'), findsNothing);
    });
  });
}
