import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/app/app.dart';

void main() {
  testWidgets('التطبيق يفتح ويعرض كارت الترحيب', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuranCenterApp()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_welcome')), findsOneWidget);
  });
}
