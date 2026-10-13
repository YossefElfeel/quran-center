import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/core/utils/arabic_numerals.dart';
import 'package:quran_center/features/notifications/domain/app_notification.dart';
import 'package:quran_center/features/notifications/notification_router.dart';
import 'package:quran_center/features/session/data/session_cache.dart';
import 'package:quran_center/features/session/domain/attendance_status.dart';
import 'package:quran_center/features/session/domain/roster_entry.dart';
import 'package:quran_center/features/session/presentation/widgets/score_pad.dart';
import 'package:quran_center/features/session/presentation/widgets/student_tile.dart';
import 'package:quran_center/features/subscription/domain/household_summary.dart';
import 'package:quran_center/features/subscription/domain/subscription_status.dart';
import 'package:quran_center/features/subscription/presentation/widgets/record_payment_sheet.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:quran_center/shared/theme/tokens.dart';
import 'package:quran_center/shared/widgets/app_async_form_sheet.dart';
import 'package:quran_center/shared/widgets/app_list_card.dart';
import 'package:quran_center/shared/widgets/app_modal_sheet.dart';
import 'package:quran_center/shared/widgets/app_text_field.dart';

Widget wrap(Widget child, {double scale = 1}) => ProviderScope(
  child: MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    builder: (context, body) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: body!,
    ),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);
double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
}

void main() {
  testWidgets(
    'Save sheet validates, preserves failed input, and blocks duplicate slow saves',
    (tester) async {
      final text = TextEditingController();
      final pending = Completer<void>();
      int calls = 0;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppModalSheet<void>(
                context: context,
                builder: (_) => AppAsyncFormSheet(
                  submitLabel: 'احفظ',
                  successMessage: 'اتحفظ',
                  fields: [
                    AppTextField(
                      controller: text,
                      label: 'الاسم',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'اكتب الاسم' : null,
                    ),
                  ],
                  onSubmit: () async {
                    calls++;
                    if (calls == 1) throw StateError('network');
                    await pending.future;
                  },
                ),
              ),
              child: const Text('افتح'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('احفظ'));
      await tester.pump();
      expect(find.text('اكتب الاسم'), findsOneWidget);
      expect(calls, 0);
      await tester.enterText(find.byType(TextFormField), 'أحمد');
      await tester.tap(find.text('احفظ'));
      await tester.pump();
      await tester.pump();
      expect(
        find.text('تعذّر الحفظ — بياناتك لسه هنا، جرّب تاني'),
        findsOneWidget,
      );
      expect(text.text, 'أحمد');
      await tester.tap(find.text('احفظ'));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).last, warnIfMissed: false);
      await tester.pump();
      expect(calls, 2);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('اتحفظ'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      text.dispose();
    },
  );
  test(
    'Closed offline details retain default attendance after a cache round trip',
    () {
      const session = TodaySession(
        sessionId: 's',
        roster: [
          RosterEntry(
            enrollmentId: 'unrecorded',
            studentPersonId: 'p1',
            studentName: 'أحمد',
            attendance: AttendanceStatus.absent,
          ),
          RosterEntry(
            enrollmentId: 'absent',
            studentPersonId: 'p2',
            studentName: 'محمد',
            attendance: AttendanceStatus.absent,
            attendanceRecorded: true,
          ),
        ],
      );
      final closed = decodeTodaySession(
        encodeTodaySession(session.closedLocally(markUnrecordedPresent: true)),
      );
      expect(closed.closedToday, true);
      expect(closed.presentCount, 1);
      expect(closed.absentCount, 1);
      expect(closed.roster.first.attendance, AttendanceStatus.present);
      expect(closed.roster.every((e) => e.attendanceRecorded), true);
      final unchanged = session.closedLocally(markUnrecordedPresent: false);
      expect(unchanged.presentCount, 0);
      expect(unchanged.roster.first.attendanceRecorded, false);
    },
  );
  test(
    'Arabic and Persian digits normalize without accepting malformed values',
    () {
      expect(parseLocalizedInt('٢٥'), 25);
      expect(parseLocalizedInt('۲۵'), 25);
      expect(parseLocalizedInt('٢x'), null);
      expect(parseLocalizedDouble('١٢٫٥'), 12.5);
    },
  );
  test('All five palettes provide AA text on semantic backgrounds', () {
    for (final p in <AppPalette>[
      AppPalette.light,
      AppPalette.dark,
      AppPalette.amoled,
      AppPalette.highContrastLight,
      AppPalette.highContrastDark,
    ]) {
      for (final pair in <(Color, Color)>[
        (p.success, p.onSuccess),
        (p.warning, p.onWarning),
        (p.error, p.onError),
        (p.accent, p.onAccent),
        (p.background, p.warningText),
        (p.background, p.accentText),
      ]) {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
    }
  });
  test(
    'A closed cache becomes available to open on the next day, while pending close stays visible',
    () {
      final map =
          jsonDecode(
                encodeTodaySession(
                  const TodaySession(
                    sessionId: 's',
                    closedToday: true,
                    roster: <RosterEntry>[],
                  ),
                ),
              )
              as Map<String, dynamic>;
      map['cached_day'] = '2026-01-01';
      final json = jsonEncode(map);
      expect(
        decodeTodaySession(json, now: DateTime(2026, 1, 2)).sessionId,
        isNull,
      );
      expect(
        decodeTodaySession(
          json,
          now: DateTime(2026, 1, 2),
          preserveSession: true,
        ).closedToday,
        isTrue,
      );
      expect(const TodaySession(roster: <RosterEntry>[]).isOpen, isFalse);
      expect(
        const TodaySession(sessionId: 's', roster: <RosterEntry>[]).isOpen,
        isTrue,
      );
      expect(
        const TodaySession(
          sessionId: 's',
          closedToday: true,
          roster: <RosterEntry>[],
        ).isOpen,
        isFalse,
      );
    },
  );
  test(
    'Returned evaluation keeps its historical month and every routed notification has a safe role destination',
    () {
      final n = AppNotification(
        id: 'n',
        type: 'monthly_eval_returned',
        title: 'x',
        circleId: 'c',
        month: '2026-08-01',
        createdAt: DateTime(2026),
      );
      expect(
        notificationRoute(n, <String>['teacher']),
        contains('month=2026-08-01'),
      );
      final expected = <String, String?>{
        'subscription_overdue': '/parent/subscription',
        'certificate_candidate': null,
        'excuse_decided': null,
        'development_returned': null,
      };
      for (final e in expected.entries) {
        expect(
          notificationRoute(
            AppNotification(
              id: 'n',
              type: e.key,
              title: 'x',
              createdAt: DateTime(2026),
            ),
            <String>['parent'],
          ),
          e.value,
        );
      }
    },
  );
  testWidgets(
    'Numeric form accepts Arabic digits and exposes required validation',
    (tester) async {
      final controller = TextEditingController();
      final key = GlobalKey<FormState>();
      await tester.pumpWidget(
        wrap(
          Form(
            key: key,
            child: AppTextField(
              controller: controller,
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'اكتب المبلغ' : null,
            ),
          ),
        ),
      );
      key.currentState!.validate();
      await tester.pump();
      expect(find.text('اكتب المبلغ'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '٢٥');
      expect(controller.text, '25');
      controller.dispose();
    },
  );
  testWidgets('RTL list card has the shared drill-in icon', (tester) async {
    await tester.pumpWidget(wrap(AppListCard(title: 'حلقة', onTap: () {})));
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
  testWidgets('Payment requires review before the server write', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => RecordPaymentSheet(
            feedbackContext: context,
            household: const HouseholdSummary(
              id: 'h',
              name: 'أسرة',
              monthlyAmount: 10,
              status: SubscriptionStatus.overdue,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('مراجعة وتسجيل الدفعة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('تأكيد الدفعة'), findsOneWidget);
  });
  testWidgets(
    'Student actions and score cells fit a phone at 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(375, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        wrap(
          Column(
            children: <Widget>[
              StudentTile(
                entry: const RosterEntry(
                  enrollmentId: 'e',
                  studentPersonId: 'p',
                  studentName: 'محمد عبد الرحمن محمد أحمد',
                  attendance: AttendanceStatus.absent,
                ),
                canRecordTasmee: true,
                onAttendanceChanged: (_) {},
                onTasmee: () {},
                onNote: () {},
                onRequestExcuse: () {},
              ),
              ScorePad(selected: 8, threshold: 7, onSelected: (_) {}),
            ],
          ),
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
