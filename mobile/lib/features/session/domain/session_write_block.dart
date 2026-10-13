/// سبب إيقاف تسجيل الحصص من الإدارة (ناتج RPC `session_writes_blocked`).
enum SessionWriteBlock {
  freezeSessions('freeze_sessions'),
  maintenanceMode('maintenance_mode');

  const SessionWriteBlock(this.dbValue);

  final String dbValue;

  /// قيمة غير معروفة أو null → مفيش إيقاف.
  static SessionWriteBlock? fromDb(Object? value) {
    for (final SessionWriteBlock b in SessionWriteBlock.values) {
      if (b.dbValue == value) return b;
    }
    return null;
  }
}

/// الكتابة اترفضت لأن الإدارة موقفة تسجيل الحصص مؤقتًا (تجميد/صيانة).
/// عابر: السجلات بتفضل محفوظة وبتتبعت أول ما الإيقاف يتشال.
class SessionWritesBlockedException implements Exception {
  const SessionWritesBlockedException(this.reason);

  final SessionWriteBlock reason;

  @override
  String toString() => 'SessionWritesBlockedException(${reason.dbValue})';
}

/// هل الخطأ رفض صلاحية (RLS / Postgres 42501)؟ — الحالة الوحيدة اللي بنسأل
/// فيها السيرفر عن سبب الإيقاف.
bool isPermissionDeniedError(Object error) {
  final String s = error.toString().toLowerCase();
  return s.contains('42501') ||
      s.contains('permission denied') ||
      s.contains('row-level security');
}
