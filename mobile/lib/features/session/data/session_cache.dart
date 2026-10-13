import 'dart:convert';

import '../../enrollment/domain/gender.dart';
import '../../progress_engine/domain/ledger_state.dart';
import '../domain/attendance_status.dart';
import '../domain/portion.dart';
import '../domain/roster_entry.dart';

/// تسلسل/فكّ تسلسل "حصة النهارده" للكاش المحلي (Drift) — عشان الشاشة تفتح
/// أوفلاين بعد إعادة تشغيل التطبيق. بيعيش في طبقة البيانات (الدومين يفضل نقي).

Map<String, dynamic> _portionToJson(Portion p) => <String, dynamic>{
  'id': p.id,
  'name': p.name,
  'surah_start': p.surahStart,
  'ayah_start': p.ayahStart,
  'surah_end': p.surahEnd,
  'ayah_end': p.ayahEnd,
};

Map<String, dynamic> _rosterEntryToJson(RosterEntry e) => <String, dynamic>{
  'enrollment_id': e.enrollmentId,
  'student_person_id': e.studentPersonId,
  'student_name': e.studentName,
  'attendance': e.attendance.dbValue,
  'gender': e.gender?.dbValue,
  'attendance_recorded': e.attendanceRecorded,
  'excuse_requested': e.excuseRequested,
  'tasmee_recorded': e.tasmeeRecorded,
  'ledger_state': e.ledgerState?.dbValue,
};

RosterEntry _rosterEntryFromJson(Map<String, dynamic> m) {
  final String? ledger = m['ledger_state'] as String?;
  return RosterEntry(
    enrollmentId: m['enrollment_id'] as String,
    studentPersonId: m['student_person_id'] as String,
    studentName: m['student_name'] as String,
    attendance: AttendanceStatus.fromDb(m['attendance'] as String),
    gender: Gender.fromDb(m['gender'] as String?),
    attendanceRecorded: m['attendance_recorded'] as bool? ?? false,
    excuseRequested: m['excuse_requested'] as bool? ?? false,
    tasmeeRecorded: m['tasmee_recorded'] as bool? ?? false,
    ledgerState: ledger == null ? null : LedgerState.fromDb(ledger),
  );
}

/// يرمّز الحصة (مع الروستر والمقطع والمراجعة) لـ JSON نصّي للتخزين.
String encodeTodaySession(TodaySession s) => jsonEncode(<String, dynamic>{
  'session_id': s.sessionId,
  'closed_today': s.closedToday,
  'cached_day': DateTime.now().toIso8601String().substring(0, 10),
  'present_count': s.presentCount,
  'absent_count': s.absentCount,
  'tasmee_count': s.tasmeeCount,
  'active_at_open': s.activeAtOpen,
  'current_portion': s.currentPortion == null
      ? null
      : _portionToJson(s.currentPortion!),
  'required_revision': s.requiredRevision == null
      ? null
      : _portionToJson(s.requiredRevision!),
  'roster': s.roster.map(_rosterEntryToJson).toList(),
});

/// يفك JSON المخزّن لـ [TodaySession] (للعرض أوفلاين).
TodaySession decodeTodaySession(
  String json, {
  DateTime? now,
  bool preserveSession = false,
}) {
  final Map<String, dynamic> m = jsonDecode(json) as Map<String, dynamic>;
  final bool staleClosed =
      !preserveSession &&
      m['closed_today'] == true &&
      m['cached_day'] !=
          (now ?? DateTime.now()).toIso8601String().substring(0, 10);
  final Map<String, dynamic>? cp =
      m['current_portion'] as Map<String, dynamic>?;
  final Map<String, dynamic>? rr =
      m['required_revision'] as Map<String, dynamic>?;
  return TodaySession(
    sessionId: staleClosed ? null : m['session_id'] as String?,
    closedToday: !staleClosed && (m['closed_today'] as bool? ?? false),
    presentCount: m['present_count'] as int? ?? 0,
    absentCount: m['absent_count'] as int? ?? 0,
    tasmeeCount: m['tasmee_count'] as int? ?? 0,
    activeAtOpen: (m['active_at_open'] as num?)?.toInt() ?? 0,
    currentPortion: cp == null ? null : Portion.fromMap(cp),
    requiredRevision: rr == null ? null : Portion.fromMap(rr),
    roster: <RosterEntry>[
      for (final dynamic r in m['roster'] as List<dynamic>)
        _rosterEntryFromJson(r as Map<String, dynamic>),
    ],
  );
}
