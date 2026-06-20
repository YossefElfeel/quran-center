import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:quran_center/shared/widgets/app_button.dart';
import 'package:quran_center/shared/widgets/app_list_card.dart';

/// يلفّ الـ widget في MaterialApp عربي (RTL). context.palette بيرجع للوحة
/// الافتراضية لو الثيم مش موجود، فمحتاجينش نحقن ThemeExtension.
Widget _wrap(Widget child, {TextScaler? textScaler}) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  home: Builder(
    builder: (BuildContext context) {
      final Widget scaffold = Scaffold(body: Center(child: child));
      if (textScaler == null) return scaffold;
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: scaffold,
      );
    },
  ),
);

void main() {
  group('AppListCard — إتاحة', () {
    testWidgets('بـ onTap → فيه node قابل للّمس (semantics tap action)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AppListCard(
            title: 'عنوان البطاقة',
            subtitle: 'سطر فرعي',
            leadingIcon: Icons.book_outlined,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      // إجراء الـ tap عايش على عقدة الـ InkWell (جوّا AppCard) — وهي أب
      // لحدود MergeSemantics اللي بتلمّ النص، فبنستعلم عنها من الـ InkWell
      // نفسه. isSemantics matcher بيتعامل مع الإجراءات داخليًا (يتفادى
      // hasAction المهجور).
      final Finder cardInk = find.descendant(
        of: find.byType(AppListCard),
        matching: find.byType(InkWell),
      );
      expect(cardInk, findsOneWidget);
      expect(
        tester.getSemantics(cardInk),
        isSemantics(hasTapAction: true),
        reason: 'البطاقة القابلة للنقر لازم تعرّض إجراء tap',
      );
      // والنص نفسه مدموج في عقدة واحدة (حدود الدمج).
      expect(
        tester
            .getSemantics(find.text('عنوان البطاقة'))
            .getSemanticsData()
            .label,
        'عنوان البطاقة\nسطر فرعي',
      );
    });

    testWidgets('MergeSemantics بيدمج العنوان + السطر الفرعي في node واحد', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AppListCard(
            title: 'اسم الطالب',
            subtitle: 'الحلقة الأولى',
            leadingIcon: Icons.person_outline,
          ),
        ),
      );
      await tester.pump();

      // عنوان وسطر فرعي مدموجين → عقدة واحدة لابلها بيحتوي الاتنين.
      final SemanticsNode node = tester.getSemantics(find.text('اسم الطالب'));
      final String label = node.getSemanticsData().label;
      expect(label, contains('اسم الطالب'));
      expect(
        label,
        contains('الحلقة الأولى'),
        reason: 'MergeSemantics لازم يضمّ العنوان والسطر الفرعي في عقدة واحدة',
      );
    });
  });

  group('AppButton — إتاحة', () {
    testWidgets('له علم button في شجرة الـ semantics + التسمية موجودة', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(AppButton(label: 'حفظ', onPressed: () {})));
      await tester.pump();

      // isSemantics بيتعامل مع واجهة الأعلام داخليًا (يتفادى hasFlag المهجور).
      expect(
        tester.getSemantics(find.text('حفظ')),
        isSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          label: 'حفظ',
        ),
        reason: 'AppButton مفعّل لازم يكون button + enabled وتسميته في الشجرة',
      );
    });

    testWidgets('زر معطّل (onPressed=null) → مش enabled لكن لسه button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AppButton(label: 'إرسال', onPressed: null)),
      );
      await tester.pump();

      // لسه button، وله enabled-state لكن غير مفعّل (isEnabled=false).
      expect(
        tester.getSemantics(find.text('إرسال')),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
        reason: 'onPressed=null لازم يطلّع الزر button غير مفعّل',
      );
    });
  });

  group('تكبير الخط (textScaler) — من غير تجاوز/استثناء', () {
    testWidgets('AppListCard عند textScaler 1.8 يرسم من غير FlutterError', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AppListCard(
            title: 'عنوان طويل نسبيًا لاختبار التكبير',
            subtitle: 'سطر فرعي ممكن يلتفّ على أكتر من سطر عند التكبير',
            leadingIcon: Icons.info_outline,
            trailing: Icon(Icons.chevron_left),
          ),
          textScaler: const TextScaler.linear(1.8),
        ),
      );
      await tester.pump();

      // أي overflow/تجاوز تخطيط بيرفع FlutterError يتلقطه takeException.
      expect(tester.takeException(), isNull);
      expect(find.byType(AppListCard), findsOneWidget);
    });

    testWidgets('AppButton عند textScaler 1.8 يرسم من غير استثناء', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(label: 'زر بنص للتكبير', onPressed: () {}),
          textScaler: const TextScaler.linear(1.8),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(AppButton), findsOneWidget);
    });
  });
}
