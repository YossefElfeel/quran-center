/// حالة مقطع في دفتر الطالب (الدَيْن/backlog).
enum LedgerState {
  assigned,
  failedRetry,
  passed;

  String get dbValue => switch (this) {
    LedgerState.assigned => 'assigned',
    LedgerState.failedRetry => 'failed_retry',
    LedgerState.passed => 'passed',
  };

  static LedgerState fromDb(String value) => switch (value) {
    'failed_retry' => LedgerState.failedRetry,
    'passed' => LedgerState.passed,
    _ => LedgerState.assigned,
  };
}
