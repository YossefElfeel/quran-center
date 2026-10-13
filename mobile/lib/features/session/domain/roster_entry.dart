import '../../enrollment/domain/gender.dart';
import '../../progress_engine/domain/ledger_state.dart';
import '../../progress_engine/domain/progress_engine.dart';
import 'attendance_status.dart';
import 'portion.dart';

/// قيمة حارسة للتفرقة بين "ماتمرّرش" و"تمرّر null صراحةً" في copyWith.
const Object _unset = Object();

/// صف في روستر الحصة (طالب + حضوره + حالته على المقطع الحالي).
class RosterEntry {
  const RosterEntry({
    required this.enrollmentId,
    required this.studentPersonId,
    required this.studentName,
    required this.attendance,
    this.gender,
    this.attendanceRecorded = false,
    this.excuseRequested = false,
    this.tasmeeRecorded = false,
    this.ledgerState,
  });

  final String enrollmentId;
  final String studentPersonId;
  final String studentName;
  final AttendanceStatus attendance;
  final Gender? gender;
  final bool attendanceRecorded;
  final bool excuseRequested;
  final bool tasmeeRecorded;

  /// حالة الطالب على المقطع الحالي (null = لسه متسمّعش عليه).
  final LedgerState? ledgerState;

  /// [ledgerState] بيقبل null صريح (لتصفير الحالة بعد الانتقال) عبر الحارس.
  RosterEntry copyWith({
    AttendanceStatus? attendance,
    bool? attendanceRecorded,
    bool? excuseRequested,
    bool? tasmeeRecorded,
    Object? ledgerState = _unset,
  }) => RosterEntry(
    enrollmentId: enrollmentId,
    studentPersonId: studentPersonId,
    studentName: studentName,
    attendance: attendance ?? this.attendance,
    gender: gender,
    attendanceRecorded: attendanceRecorded ?? this.attendanceRecorded,
    excuseRequested: excuseRequested ?? this.excuseRequested,
    tasmeeRecorded: tasmeeRecorded ?? this.tasmeeRecorded,
    ledgerState: identical(ledgerState, _unset)
        ? this.ledgerState
        : ledgerState as LedgerState?,
  );
}

/// حالة "حصة النهارده": الحصة المفتوحة + المقطع الحالي + المقام المجمّد
/// + المراجعة المطلوبة + الروستر.
class TodaySession {
  const TodaySession({
    required this.roster,
    this.sessionId,
    this.currentPortion,
    this.activeAtOpen = 0,
    this.requiredRevision,
    this.closedToday = false,
    this.presentCount = 0,
    this.absentCount = 0,
    this.tasmeeCount = 0,
  });

  final String? sessionId;
  final bool closedToday;
  final int presentCount;
  final int absentCount;
  final int tasmeeCount;
  final Portion? currentPortion;

  /// المقام المجمّد: عدد النشطين وقت فتح المقطع الحالي (٠ لو مفيش مقطع).
  final int activeAtOpen;

  /// المراجعة المطلوبة النهارده (من خطة الحصة السابقة) أو null.
  final Portion? requiredRevision;

  final List<RosterEntry> roster;

  /// Keep the offline summary and details consistent with queued attendance.
  TodaySession closedLocally({required bool markUnrecordedPresent}) {
    final List<RosterEntry> recorded = roster
        .map(
          (e) => markUnrecordedPresent && !e.attendanceRecorded
              ? e.copyWith(
                  attendance: AttendanceStatus.present,
                  attendanceRecorded: true,
                )
              : e,
        )
        .toList();
    return TodaySession(
      sessionId: sessionId,
      closedToday: true,
      currentPortion: currentPortion,
      requiredRevision: requiredRevision,
      activeAtOpen: activeAtOpen,
      roster: recorded,
      presentCount: recorded
          .where(
            (e) =>
                e.attendanceRecorded &&
                (e.attendance == AttendanceStatus.present ||
                    e.attendance == AttendanceStatus.late),
          )
          .length,
      absentCount: recorded
          .where(
            (e) =>
                e.attendanceRecorded && e.attendance == AttendanceStatus.absent,
          )
          .length,
      tasmeeCount: recorded.where((e) => e.tasmeeRecorded).length,
    );
  }

  bool get isOpen => sessionId != null && !closedToday;
  bool get hasPortion => currentPortion != null;

  /// عدد اللي عدّوا المقطع الحالي.
  int get passedCount => roster
      .where((RosterEntry e) => e.ledgerState == LedgerState.passed)
      .length;

  /// عدد اللي عليهم دَيْن على المقطع الحالي.
  int get debtCount => roster
      .where((RosterEntry e) => e.ledgerState == LedgerState.failedRetry)
      .length;

  /// نقترح انتقال المجموعة؟ (مقام مجمّد على النشطين وقت فتح المقطع، >٥٠٪).
  bool get shouldAdvance =>
      hasPortion &&
      activeAtOpen > 0 &&
      ProgressEngine.evaluateAdvance(
        activeAtPortionOpen: activeAtOpen,
        passedCount: passedCount,
      ).shouldAdvance;

  TodaySession copyWith({
    List<RosterEntry>? roster,
    String? sessionId,
    bool? closedToday,
  }) => TodaySession(
    sessionId: sessionId ?? this.sessionId,
    closedToday: closedToday ?? this.closedToday,
    presentCount: presentCount,
    absentCount: absentCount,
    tasmeeCount: tasmeeCount,
    currentPortion: currentPortion,
    activeAtOpen: activeAtOpen,
    requiredRevision: requiredRevision,
    roster: roster ?? this.roster,
  );
}
