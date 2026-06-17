import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/progress_engine/domain/ledger_state.dart';
import 'package:quran_center/features/session/data/current_cycle.dart';
import 'package:quran_center/features/session/data/surah_option.dart';
import 'package:quran_center/features/session/domain/attendance_status.dart';
import 'package:quran_center/features/session/domain/portion.dart';
import 'package:quran_center/features/session/domain/roster_entry.dart';
import 'package:quran_center/features/session/domain/tasmee_kind.dart';
import 'package:quran_center/features/session/presentation/widgets/portion_range_row.dart';

const Portion _p = Portion(
  id: 'x',
  name: 'أول البقرة',
  surahStart: 2,
  ayahStart: 1,
  surahEnd: 2,
  ayahEnd: 5,
);

RosterEntry _e(String id, LedgerState? s) => RosterEntry(
  enrollmentId: id,
  studentPersonId: 'p_$id',
  studentName: 'ط $id',
  attendance: AttendanceStatus.present,
  ledgerState: s,
);

void main() {
  group('TodaySession.shouldAdvance — المقام المجمّد', () {
    test('فوق النص (٢ من ٣) → يقترح الانتقال', () {
      final TodaySession s = TodaySession(
        sessionId: 's',
        currentPortion: _p,
        activeAtOpen: 3,
        roster: <RosterEntry>[
          _e('1', LedgerState.passed),
          _e('2', LedgerState.passed),
          _e('3', null),
        ],
      );
      expect(s.shouldAdvance, isTrue);
    });

    test('بالظبط النص (١ من ٢) → مايقترحش', () {
      final TodaySession s = TodaySession(
        sessionId: 's',
        currentPortion: _p,
        activeAtOpen: 2,
        roster: <RosterEntry>[_e('1', LedgerState.passed), _e('2', null)],
      );
      expect(s.shouldAdvance, isFalse);
    });

    test('مقام مجمّد صفر → مايقترحش', () {
      final TodaySession s = TodaySession(
        sessionId: 's',
        currentPortion: _p,
        roster: <RosterEntry>[_e('1', LedgerState.passed)],
      );
      expect(s.shouldAdvance, isFalse);
    });

    test('مفيش مقطع → مايقترحش', () {
      const TodaySession s = TodaySession(roster: <RosterEntry>[]);
      expect(s.shouldAdvance, isFalse);
    });
  });

  group('RosterEntry.copyWith — تصفير الدَيْن بالحارس', () {
    test('null صريح يصفّر ledgerState', () {
      final RosterEntry e = _e('1', LedgerState.passed);
      expect(e.copyWith(ledgerState: null).ledgerState, isNull);
    });

    test('عدم التمرير يحافظ على ledgerState', () {
      final RosterEntry e = _e('1', LedgerState.passed);
      final RosterEntry after = e.copyWith(attendance: AttendanceStatus.absent);
      expect(after.ledgerState, LedgerState.passed);
      expect(after.attendance, AttendanceStatus.absent);
    });
  });

  group('portionRangeError — تحقّق النطاق', () {
    const List<SurahOption> surahs = <SurahOption>[
      SurahOption(number: 1, name: 'الفاتحة', ayahCount: 7),
      SurahOption(number: 2, name: 'البقرة', ayahCount: 286),
    ];

    test('نطاق سليم → null', () {
      expect(
        portionRangeError(
          surahs: surahs,
          name: 'م',
          surahStart: 2,
          ayahStart: 1,
          surahEnd: 2,
          ayahEnd: 5,
        ),
        isNull,
      );
    });

    test('آية أكبر من آيات السورة → خطأ', () {
      expect(
        portionRangeError(
          surahs: surahs,
          name: 'م',
          surahStart: 1,
          ayahStart: 1,
          surahEnd: 1,
          ayahEnd: 99,
        ),
        isNotNull,
      );
    });

    test('النهاية قبل البداية → خطأ', () {
      expect(
        portionRangeError(
          surahs: surahs,
          name: 'م',
          surahStart: 2,
          ayahStart: 10,
          surahEnd: 2,
          ayahEnd: 5,
        ),
        isNotNull,
      );
    });

    test('خانة ناقصة → خطأ', () {
      expect(
        portionRangeError(
          surahs: surahs,
          name: '',
          surahStart: 2,
          ayahStart: 1,
          surahEnd: 2,
          ayahEnd: 5,
        ),
        isNotNull,
      );
    });
  });

  group('CurrentCycle.fromMap + TasmeeKind', () {
    test('بيقرأ المقطع والمقام المجمّد', () {
      final CurrentCycle c = CurrentCycle.fromMap(<String, dynamic>{
        'id': 'cyc',
        'active_at_open': 4,
        'portion': <String, dynamic>{
          'id': 'p',
          'name': 'ن',
          'surah_start': 2,
          'ayah_start': 1,
          'surah_end': 2,
          'ayah_end': 5,
        },
      });
      expect(c.cycleId, 'cyc');
      expect(c.activeAtOpen, 4);
      expect(c.portion.name, 'ن');
    });

    test('active_at_open مفقود → صفر', () {
      final CurrentCycle c = CurrentCycle.fromMap(<String, dynamic>{
        'id': 'cyc',
        'portion': <String, dynamic>{
          'id': 'p',
          'name': 'ن',
          'surah_start': 2,
          'ayah_start': 1,
          'surah_end': 2,
          'ayah_end': 5,
        },
      });
      expect(c.activeAtOpen, 0);
    });

    test('TasmeeKind.dbValue', () {
      expect(TasmeeKind.memorization.dbValue, 'memorization');
      expect(TasmeeKind.revision.dbValue, 'revision');
    });
  });
}
