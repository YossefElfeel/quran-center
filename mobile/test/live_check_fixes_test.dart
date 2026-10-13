import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/core/auth/auth_providers.dart';
import 'package:quran_center/core/settings/settings_repository.dart';
import 'package:quran_center/core/utils/arabic_date.dart';
import 'package:quran_center/features/excuse/domain/pending_excuse.dart';
import 'package:quran_center/features/excuse/presentation/excuse_labels.dart';
import 'package:quran_center/features/excuse/presentation/widgets/excuse_decision_tile.dart';
import 'package:quran_center/features/home/presentation/screens/dashboard_screen.dart';
import 'package:quran_center/features/parent_portal/domain/child_summary.dart';
import 'package:quran_center/features/parent_portal/presentation/controllers/my_children_controller.dart';
import 'package:quran_center/features/session/domain/attendance_status.dart';
import 'package:quran_center/features/session/domain/roster_entry.dart';
import 'package:quran_center/features/session/presentation/widgets/student_tile.dart';
import 'package:quran_center/features/subscription/domain/household_summary.dart';
import 'package:quran_center/features/subscription/domain/subscription_logic.dart';
import 'package:quran_center/features/subscription/domain/subscription_status.dart';
import 'package:quran_center/features/subscription/presentation/controllers/my_subscription_controller.dart';
import 'package:quran_center/features/subscription/presentation/widgets/subscription_status_view.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

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
  group('subscription — total due + month names', () {
    test('dueMonths skips paid months and months before the household', () {
      final List<DateTime> due = dueMonths(
        today: DateTime(2026, 10, 13),
        householdCreatedAt: DateTime(2026, 6, 20),
        paidMonths: <DateTime>[DateTime(2026, 7), DateTime(2026, 6)],
        monthlyAmount: 100,
      );
      expect(due, <DateTime>[
        DateTime(2026, 10),
        DateTime(2026, 9),
        DateTime(2026, 8),
      ]);
      expect(totalDue(months: due.length, monthlyAmount: 100), 300);
    });

    test('exempt households owe nothing', () {
      expect(
        dueMonths(
          today: DateTime(2026, 10, 13),
          householdCreatedAt: DateTime(2025),
          paidMonths: const <DateTime>[],
          monthlyAmount: 0,
        ),
        isEmpty,
      );
      expect(totalDue(months: 4, monthlyAmount: 0), 0);
    });

    test('admin overdue row: months late × monthly amount', () {
      final HouseholdSummary h = HouseholdSummary(
        id: 'h',
        name: 'أسرة',
        monthlyAmount: 100,
        status: SubscriptionStatus.overdue,
        lastPaidMonth: DateTime(2026, 6),
      );
      final DateTime today = DateTime(2026, 10, 13);
      expect(h.monthsLate(today), 4);
      expect(h.amountDue(today), 400);
      expect(
        monthsBehind(lastPaidMonth: null, today: today),
        isNull,
        reason: 'no payments at all → unknown, not zero',
      );
    });

    testWidgets('status view shows total due, month names and gate banner', (
      WidgetTester tester,
    ) async {
      final DateTime now = DateTime.now();
      final DateTime created = DateTime(now.year, now.month - 3);
      await tester.pumpWidget(
        _app(
          const SubscriptionStatusView(
            redirectedFromChild: true,
            childName: 'يوسف',
          ),
          overrides: <Override>[
            appSettingsProvider.overrideWith(
              (Ref ref) async => AppSettings.defaults,
            ),
            subscriptionDetailsProvider.overrideWith(
              (Ref ref) async => (
                <HouseholdBilling>[
                  HouseholdBilling(
                    <String, dynamic>{
                      'id': 'h1',
                      'name': 'أسرة يوسف',
                      'monthly_amount': 100,
                      'created_at': created.toIso8601String(),
                    },
                    const [],
                    const <DateTime>[],
                  ),
                ],
                false,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('علشان تتابع يوسف لازم الاشتراك يتجدد'), findsOneWidget);
      expect(find.text('المطلوب: ٤٠٠ ج.م'), findsOneWidget);
      expect(find.text('عن ٤ شهور'), findsOneWidget);
      expect(
        find.textContaining(arabicMonthLabel(DateTime(now.year, now.month))),
        findsOneWidget,
      );
      expect(find.textContaining('/'), findsNothing);
    });
  });

  testWidgets('parent home locks child summaries when not subscribed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const DashboardScreen(),
        overrides: <Override>[
          currentRolesProvider.overrideWith(
            (Ref ref) async => <String>['parent'],
          ),
          homeNameProvider.overrideWith((Ref ref) async => 'أحمد'),
          appSettingsProvider.overrideWith(
            (Ref ref) async => AppSettings.defaults,
          ),
          myChildrenProvider.overrideWith(
            (Ref ref) async => const <ChildSummary>[
              ChildSummary(studentPersonId: 's1', fullName: 'يوسف أحمد'),
            ],
          ),
          mySubscriptionActiveProvider.overrideWith((Ref ref) async => false),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('يوسف أحمد'), findsOneWidget);
    expect(find.text('التفاصيل متاحة بعد تجديد الاشتراك'), findsOneWidget);
    expect(find.textContaining('حضور الشهر'), findsNothing);
    // "اشتراكي" في قسم لوحده تحت الولاد.
    expect(find.text('الاشتراك'), findsOneWidget);
    expect(find.text('اشتراكي'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('اشتراكي')).dy,
      greaterThan(tester.getTopLeft(find.text('يوسف أحمد')).dy),
    );
  });

  group('session student tile', () {
    const RosterEntry entry = RosterEntry(
      enrollmentId: 'e',
      studentPersonId: 'p',
      studentName: 'محمد',
      attendance: AttendanceStatus.present,
    );

    testWidgets('no portion → disabled "سمّع" + hint that opens set-portion', (
      WidgetTester tester,
    ) async {
      int setPortion = 0;
      int tasmee = 0;
      await tester.pumpWidget(
        _app(
          StudentTile(
            entry: entry,
            canRecordTasmee: false,
            onAttendanceChanged: (_) {},
            onTasmee: () => tasmee++,
            onNote: () {},
            onSetPortion: () => setPortion++,
          ),
        ),
      );
      final Finder button = find.widgetWithText(FilledButton, 'سمّع');
      expect(button, findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(find.text('لسه ما سمّعش'), findsOneWidget);
      expect(find.text('ملاحظة سلوك'), findsOneWidget);
      await tester.tap(find.text('حدّد مقطع الحفظ الأول'));
      expect(setPortion, 1);
      expect(tasmee, 0);
    });

    testWidgets('portion set → labeled, enabled "سمّع" button', (
      WidgetTester tester,
    ) async {
      int tasmee = 0;
      await tester.pumpWidget(
        _app(
          StudentTile(
            entry: entry,
            canRecordTasmee: true,
            onAttendanceChanged: (_) {},
            onTasmee: () => tasmee++,
          ),
        ),
      );
      expect(find.text('حدّد مقطع الحفظ الأول'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'سمّع'));
      expect(tasmee, 1);
    });
  });

  group('excuse card', () {
    final DateTime created = DateTime.now().toUtc().subtract(
      const Duration(hours: 3, minutes: 5),
    );
    final PendingExcuse excuse = PendingExcuse.fromMap(<String, dynamic>{
      'id': 'x1',
      'enrollment_id': 'e1',
      'session_id': 's1',
      'reason': 'مريض',
      'status': 'pending',
      'created_at': created.toIso8601String(),
      'decided_at': null,
      'session': <String, dynamic>{'session_date': '2026-10-11'},
      'enrollment': <String, dynamic>{
        'student': <String, dynamic>{'full_name': 'عمر'},
        'circle': <String, dynamic>{
          'name': 'حلقة الفجر',
          'teacher': <String, dynamic>{'full_name': 'أ. محمود'},
        },
      },
    });

    test('parses absence day and requester', () {
      expect(excuse.absenceDate, DateTime(2026, 10, 11));
      expect(excuse.requesterName, 'أ. محمود');
    });

    testWidgets('shows absence day + who requested it and when', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ExcuseDecisionTile(
            excuse: excuse,
            onApprove: () async {},
            onReject: () async {},
            onTap: () {},
          ),
        ),
      );
      expect(find.text('يوم الغياب: ١١ أكتوبر ٢٠٢٦'), findsOneWidget);
      expect(find.text('طلبها: أ. محمود · من ٣ ساعات'), findsOneWidget);
    });

    testWidgets('relative time phrasing', (WidgetTester tester) async {
      late AppL10n l;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (BuildContext context) {
              l = AppL10n.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final DateTime now = DateTime.utc(2026, 10, 13, 12);
      String ago(Duration d) =>
          excuseRelativeTime(l, now.subtract(d), now: now);
      expect(ago(const Duration(seconds: 20)), 'دلوقتي');
      expect(ago(const Duration(minutes: 2)), 'من دقيقتين');
      expect(ago(const Duration(hours: 1)), 'من ساعة');
      expect(ago(const Duration(days: 1)), 'امبارح');
      expect(ago(const Duration(days: 4)), 'من ٤ أيام');
      expect(ago(const Duration(days: 30)), '١٣ سبتمبر ٢٠٢٦');
    });
  });
}
