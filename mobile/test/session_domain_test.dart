import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/progress_engine/domain/ledger_state.dart';
import 'package:quran_center/features/session/domain/attendance_status.dart';
import 'package:quran_center/features/session/domain/portion.dart';
import 'package:quran_center/features/session/domain/roster_entry.dart';

RosterEntry _entry(String id, LedgerState? state) => RosterEntry(
  enrollmentId: id,
  studentPersonId: 'p_$id',
  studentName: 'طالب $id',
  attendance: AttendanceStatus.present,
  ledgerState: state,
);

void main() {
  group('TodaySession — اشتقاق العدّادات', () {
    test('passedCount/debtCount بيعدّوا الحالات الصح', () {
      final TodaySession s = TodaySession(
        sessionId: 's1',
        roster: <RosterEntry>[
          _entry('1', LedgerState.passed),
          _entry('2', LedgerState.failedRetry),
          _entry('3', LedgerState.passed),
          _entry('4', null),
        ],
      );
      expect(s.passedCount, 2);
      expect(s.debtCount, 1);
    });

    test('isOpen و hasPortion', () {
      const TodaySession closed = TodaySession(roster: <RosterEntry>[]);
      expect(closed.isOpen, isFalse);
      expect(closed.hasPortion, isFalse);

      const Portion p = Portion(
        id: 'x',
        name: 'أول البقرة',
        surahStart: 2,
        ayahStart: 1,
        surahEnd: 2,
        ayahEnd: 5,
      );
      const TodaySession open = TodaySession(
        sessionId: 's1',
        currentPortion: p,
        roster: <RosterEntry>[],
      );
      expect(open.isOpen, isTrue);
      expect(open.hasPortion, isTrue);
    });

    test('copyWith بيغيّر الروستر ويحافظ على المقطع والحصة', () {
      const Portion p = Portion(
        id: 'x',
        name: 'أول البقرة',
        surahStart: 2,
        ayahStart: 1,
        surahEnd: 2,
        ayahEnd: 5,
      );
      final TodaySession before = TodaySession(
        sessionId: 's1',
        currentPortion: p,
        roster: <RosterEntry>[_entry('1', null)],
      );
      final TodaySession after = before.copyWith(
        roster: <RosterEntry>[_entry('1', LedgerState.passed)],
      );
      expect(after.sessionId, 's1');
      expect(after.currentPortion, same(p));
      expect(after.passedCount, 1);
    });
  });

  group('Portion.fromMap', () {
    test('بيقرأ النطاق صح', () {
      final Portion p = Portion.fromMap(<String, dynamic>{
        'id': 'abc',
        'name': 'أول البقرة',
        'surah_start': 2,
        'ayah_start': 1,
        'surah_end': 2,
        'ayah_end': 5,
      });
      expect(p.id, 'abc');
      expect(p.name, 'أول البقرة');
      expect(p.surahStart, 2);
      expect(p.ayahEnd, 5);
    });
  });
}
