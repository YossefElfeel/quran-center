import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/enrollment/domain/gender.dart';
import 'package:quran_center/features/progress_engine/domain/ledger_state.dart';
import 'package:quran_center/features/session/data/session_cache.dart';
import 'package:quran_center/features/session/domain/attendance_status.dart';
import 'package:quran_center/features/session/domain/portion.dart';
import 'package:quran_center/features/session/domain/roster_entry.dart';

void main() {
  test('encode→decode round-trip للحصة الكاملة', () {
    const TodaySession session = TodaySession(
      sessionId: 's1',
      activeAtOpen: 5,
      currentPortion: Portion(
        id: 'p1',
        name: 'أول البقرة',
        surahStart: 2,
        ayahStart: 1,
        surahEnd: 2,
        ayahEnd: 20,
      ),
      requiredRevision: Portion(
        id: 'p0',
        name: 'الفاتحة',
        surahStart: 1,
        ayahStart: 1,
        surahEnd: 1,
        ayahEnd: 7,
      ),
      roster: <RosterEntry>[
        RosterEntry(
          enrollmentId: 'e1',
          studentPersonId: 'st1',
          studentName: 'محمد',
          attendance: AttendanceStatus.present,
          gender: Gender.male,
          ledgerState: LedgerState.passed,
        ),
        RosterEntry(
          enrollmentId: 'e2',
          studentPersonId: 'st2',
          studentName: 'سارة',
          attendance: AttendanceStatus.absentExcused,
          gender: Gender.female,
        ),
      ],
    );

    final TodaySession back = decodeTodaySession(encodeTodaySession(session));

    expect(back.sessionId, 's1');
    expect(back.activeAtOpen, 5);
    expect(back.currentPortion?.name, 'أول البقرة');
    expect(back.currentPortion?.surahEnd, 2);
    expect(back.requiredRevision?.id, 'p0');
    expect(back.roster.length, 2);
    expect(back.roster[0].studentName, 'محمد');
    expect(back.roster[0].attendance, AttendanceStatus.present);
    expect(back.roster[0].gender, Gender.male);
    expect(back.roster[0].ledgerState, LedgerState.passed);
    expect(back.roster[1].attendance, AttendanceStatus.absentExcused);
    expect(back.roster[1].gender, Gender.female);
    expect(back.roster[1].ledgerState, isNull);
    // المشتقّات بتشتغل على الكاش زي الأونلاين بالظبط.
    expect(back.passedCount, 1);
  });

  test('round-trip لحصة من غير مقطع/مراجعة (null-safe)', () {
    const TodaySession session = TodaySession(roster: <RosterEntry>[]);
    final TodaySession back = decodeTodaySession(encodeTodaySession(session));
    expect(back.sessionId, isNull);
    expect(back.currentPortion, isNull);
    expect(back.requiredRevision, isNull);
    expect(back.roster, isEmpty);
    expect(back.isOpen, false);
  });
}
