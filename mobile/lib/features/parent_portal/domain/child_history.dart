import '../../session/domain/attendance_status.dart';
import '../../session/domain/tasmee_kind.dart';

/// محاولة تسميع واحدة في سجلّ الطفل (حفظ أو مراجعة).
class TasmeeHistoryEntry {
  const TasmeeHistoryEntry({
    required this.date,
    required this.portionName,
    required this.score,
    required this.passed,
    required this.kind,
  });

  factory TasmeeHistoryEntry.fromMap(Map<String, dynamic> map) {
    final Object? portion = map['portion'];
    return TasmeeHistoryEntry(
      date: DateTime.parse(map['attempt_date'] as String),
      portionName: portion is Map<String, dynamic>
          ? (portion['name'] as String? ?? '')
          : '',
      score: (map['score'] as num).toInt(),
      passed: map['passed'] as bool,
      kind: TasmeeKind.fromDb(map['kind'] as String),
    );
  }

  final DateTime date;
  final String portionName;
  final int score;
  final bool passed;
  final TasmeeKind kind;
}

/// تسجيل حضور واحد في سجلّ الطفل.
class AttendanceHistoryEntry {
  const AttendanceHistoryEntry({required this.status, this.date});

  factory AttendanceHistoryEntry.fromMap(Map<String, dynamic> map) {
    final Object? session = map['session'];
    final String? dateStr = session is Map<String, dynamic>
        ? session['session_date'] as String?
        : null;
    return AttendanceHistoryEntry(
      status: AttendanceStatus.fromDb(map['status'] as String),
      date: dateStr != null ? DateTime.parse(dateStr) : null,
    );
  }

  final AttendanceStatus status;
  final DateTime? date;
}
