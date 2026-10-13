@Tags(<String>['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/session/presentation/widgets/score_pad.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

/// Golden RTL لـ ScorePad — يثبّت الشكل البصري (الخلايا، التلوين حسب حد النجاح،
/// الخلية المختارة، الأرقام العربية). الصور المرجعية بتتولّد على Linux في الـ CI
/// (workflow «Goldens») عشان تطابق بيئة المقارنة. التاج 'golden' بيتستثنى من
/// بوابة الموبايل الأساسية ويتشغّل في وظيفة goldens المخصّصة.
void main() {
  testWidgets('ScorePad — selected 8, threshold 7 (RTL)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        debugShowCheckedModeBanner: false,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                // مفاتيح الترجمة بس (من غير GlobalMaterialLocalizations) عشان
                // الثيم يفضل englishLike والصورة المرجعية ماتتغيّرش.
                child: _WithAppL10n(
                  child: ScorePad(selected: 8, threshold: 7, onSelected: _noop),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ScorePad),
      matchesGoldenFile('goldens/${Platform.operatingSystem}/score_pad.png'),
    );
  });
}

void _noop(int _) {}

class _WithAppL10n extends StatelessWidget {
  const _WithAppL10n({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    locale: const Locale('ar'),
    delegates: const <LocalizationsDelegate<dynamic>>[AppL10n.delegate],
    // Localizations بتلفّ ابنها في Directionality من WidgetsLocalizations
    // (الافتراضي LTR) — نرجّع اتجاه الأب عشان الصورة تفضل RTL زي ما هي.
    child: Directionality(
      textDirection: Directionality.of(context),
      child: child,
    ),
  );
}
