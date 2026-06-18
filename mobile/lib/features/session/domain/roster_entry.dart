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
    this.ledgerState,
  });

  final String enrollmentId;
  final String studentPersonId;
  final String studentName;
  final AttendanceStatus attendance;
  final Gender? gender;

  /// حالة الطالب على المقطع الحالي (null = لسه متسمّعش عليه).
  final LedgerState? ledgerState;

  /// [ledgerState] بيقبل null صريح (لتصفير الحالة بعد الانتقال) عبر الحارس.
  RosterEntry copyWith({
    AttendanceStatus? attendance,
    Object? ledgerState = _unset,
  }) => RosterEntry(
    enrollmentId: enrollmentId,
    studentPersonId: studentPersonId,
    studentName: studentName,
    attendance: attendance ?? this.attendance,
    gender: gender,
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
  });

  final String? sessionId;
  final Portion? currentPortion;

  /// المقام المجمّد: عدد النشطين وقت فتح المقطع الحالي (٠ لو مفيش مقطع).
  final int activeAtOpen;

  /// المراجعة المطلوبة النهارده (من خطة الحصة السابقة) أو null.
  final Portion? requiredRevision;

  final List<RosterEntry> roster;

  bool get isOpen => sessionId != null;
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

  TodaySession copyWith({List<RosterEntry>? roster}) => TodaySession(
    sessionId: sessionId,
    currentPortion: currentPortion,
    activeAtOpen: activeAtOpen,
    requiredRevision: requiredRevision,
    roster: roster ?? this.roster,
  );
}
