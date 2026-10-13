import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/enrollment/domain/enrollable_circle.dart';
import 'package:quran_center/features/enrollment/presentation/controllers/enrollable_circles_controller.dart';
import 'package:quran_center/features/enrollment/presentation/widgets/enrollable_circle_picker.dart';
import 'package:quran_center/features/intake/domain/level_option.dart';
import 'package:quran_center/features/intake/presentation/controllers/waiting_list_controller.dart';
import 'package:quran_center/features/intake/presentation/widgets/placement_sheet.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:quran_center/shared/widgets/app_button.dart';
import 'package:quran_center/shared/widgets/app_modal_sheet.dart';
import 'package:quran_center/shared/widgets/app_select_field.dart';
import 'package:quran_center/shared/widgets/app_text_field.dart';
import 'package:quran_center/shared/widgets/dispose_with.dart';

Widget _app(Widget home, {List<Override> overrides = const <Override>[]}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: home),
      ),
    );

void main() {
  group('EnrollableCircle', () {
    test('fromMap + isFull + group label', () {
      final EnrollableCircle c = EnrollableCircle.fromMap(<String, dynamic>{
        'id': 'c1',
        'name': 'حلقة أ',
        'max_size': 2,
        'level': <String, dynamic>{
          'name': 'المستوى ١',
          'curriculum': <String, dynamic>{'name': 'جزء عمّ'},
        },
        'enrollment': <dynamic>[
          <String, dynamic>{'count': 2},
        ],
      });
      expect(c.activeCount, 2);
      expect(c.isFull, isTrue);
      expect(c.groupLabel, 'جزء عمّ / المستوى ١');
      const EnrollableCircle open = EnrollableCircle(
        id: 'c2',
        name: 'ب',
        activeCount: 5,
      );
      expect(open.isFull, isFalse, reason: 'مفيش حد أقصى = مش مكتملة');
    });

    test('groupEnrollableCircles keeps curriculum → level grouping', () {
      final Map<String, List<EnrollableCircle>> g =
          groupEnrollableCircles(const <EnrollableCircle>[
            EnrollableCircle(
              id: '1',
              name: 'أ',
              activeCount: 0,
              curriculumName: 'م١',
              levelName: 'س١',
            ),
            EnrollableCircle(
              id: '2',
              name: 'ب',
              activeCount: 0,
              curriculumName: 'م١',
              levelName: 'س١',
            ),
            EnrollableCircle(
              id: '3',
              name: 'ج',
              activeCount: 0,
              curriculumName: 'م١',
              levelName: 'س٢',
            ),
          ]);
      expect(g.keys, <String>['م١ / س١', 'م١ / س٢']);
      expect(g['م١ / س١']!.length, 2);
    });
  });

  testWidgets('Circle picker blocks full circles and returns an open one', (
    WidgetTester tester,
  ) async {
    EnrollableCircle? picked;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async =>
                picked = await showEnrollableCirclePicker(context),
            child: const Text('افتح'),
          ),
        ),
        overrides: [
          enrollableCirclesProvider.overrideWith(
            (ref) async => const <EnrollableCircle>[
              EnrollableCircle(
                id: 'full',
                name: 'حلقة مليانة',
                activeCount: 10,
                maxSize: 10,
                curriculumName: 'جزء عمّ',
                levelName: 'أول',
              ),
              EnrollableCircle(
                id: 'open',
                name: 'حلقة فاضية',
                activeCount: 3,
                maxSize: 10,
                curriculumName: 'جزء عمّ',
                levelName: 'أول',
              ),
            ],
          ),
        ],
      ),
    );
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    expect(find.text('جزء عمّ / أول'), findsOneWidget);
    expect(find.text('مكتملة'), findsOneWidget);
    await tester.tap(find.text('حلقة مليانة'));
    await tester.pumpAndSettle();
    expect(picked, isNull, reason: 'الحلقة المكتملة مقفولة');

    await tester.tap(find.text('حلقة فاضية'));
    await tester.pumpAndSettle();
    expect(picked?.id, 'open');
  });

  testWidgets('AppSelectField reflects programmatic value changes', (
    WidgetTester tester,
  ) async {
    String? value = 'a';
    late StateSetter setOuter;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            setOuter = setState;
            return AppSelectField<String>(
              label: 'اختيار',
              value: value,
              hint: 'اختار',
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: 'a', child: Text('ألف')),
                DropdownMenuItem<String>(value: 'b', child: Text('باء')),
              ],
              onChanged: (String? v) => setState(() => value = v),
            );
          },
        ),
      ),
    );
    expect(find.text('ألف'), findsOneWidget);
    setOuter(() => value = 'b');
    await tester.pump();
    expect(find.text('باء'), findsOneWidget);
    expect(find.text('ألف'), findsNothing);
    setOuter(() => value = null);
    await tester.pump();
    expect(find.text('اختار'), findsOneWidget);
  });

  testWidgets('Placement save stays disabled until a level is chosen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PlacementSheet(waitingId: 'w', studentPersonId: 's'),
        overrides: [
          levelOptionsProvider.overrideWith(
            (ref) async => const <LevelOption>[
              LevelOption(id: 'l1', label: 'جزء عمّ — أول'),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    AppButton save() => tester.widget<AppButton>(find.byType(AppButton));
    expect(save().onPressed, isNull);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('جزء عمّ — أول').last);
    await tester.pumpAndSettle();
    expect(save().onPressed, isNotNull);
  });

  testWidgets('DisposeWith frees controllers only after the sheet closes', (
    WidgetTester tester,
  ) async {
    final TextEditingController name = TextEditingController();
    bool disposed = false;
    name.addListener(() {});
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showAppModalSheet<void>(
              context: context,
              builder: (BuildContext ctx) => DisposeWith(
                notifiers: <ChangeNotifier>[name],
                child: Column(
                  children: <Widget>[
                    AppTextField(controller: name, label: 'الاسم'),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('اقفل'),
                    ),
                  ],
                ),
              ),
            ),
            child: const Text('افتح'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'محمد');
    await tester.tap(find.text('اقفل'));
    // نص الأنيميشن: الحقل لسه مرسوم والكنترولر لازم يكون سليم.
    await tester.pump(const Duration(milliseconds: 50));
    expect(name.text, 'محمد');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    try {
      name.addListener(() {});
    } on FlutterError {
      disposed = true;
    }
    expect(disposed, isTrue, reason: 'اتعمله dispose بعد ما الشيت اتشال');
  });
}
