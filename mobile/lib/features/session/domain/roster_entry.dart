import '../../enrollment/domain/gender.dart';
import '../../progress_engine/domain/ledger_state.dart';
import 'attendance_status.dart';
import 'portion.dart';

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

  RosterEntry copyWith({
    AttendanceStatus? attendance,
    LedgerState? ledgerState,
  }) => RosterEntry(
    enrollmentId: enrollmentId,
    studentPersonId: studentPersonId,
    studentName: studentName,
    attendance: attendance ?? this.attendance,
    gender: gender,
    ledgerState: ledgerState ?? this.ledgerState,
  );
}

/// حالة "حصة النهارده" لحلقة: الحصة المفتوحة + المقطع الحالي + الروستر.
class TodaySession {
  const TodaySession({
    required this.roster,
    this.sessionId,
    this.currentPortion,
  });

  final String? sessionId;
  final Portion? currentPortion;
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

  TodaySession copyWith({List<RosterEntry>? roster}) => TodaySession(
    sessionId: sessionId,
    currentPortion: currentPortion,
    roster: roster ?? this.roster,
  );
}
