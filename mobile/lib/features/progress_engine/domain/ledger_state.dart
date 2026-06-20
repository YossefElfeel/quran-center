import '../../../core/logging/logger.dart';

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

  static LedgerState fromDb(String value) {
    switch (value) {
      case 'assigned':
        return LedgerState.assigned;
      case 'failed_retry':
        return LedgerState.failedRetry;
      case 'passed':
        return LedgerState.passed;
    }
    AppLog.warn('Unknown ledger state from server: $value');
    return LedgerState.assigned;
  }
}
