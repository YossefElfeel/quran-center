@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/session/presentation/widgets/score_pad.dart';

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
                child: ScorePad(selected: 8, threshold: 7, onSelected: _noop),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ScorePad),
      matchesGoldenFile('goldens/score_pad.png'),
    );
  });
}

void _noop(int _) {}
