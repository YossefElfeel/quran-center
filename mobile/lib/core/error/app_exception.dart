/// هرم استثناءات التطبيق. الـ repositories بتمسك أخطاء Supabase/الشبكة
/// وتحوّلها لواحدة من دول (رفض RLS → [PermissionDeniedException] مش crash).
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = '']);
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException([super.message = '']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = '']);
}

class ValidationException extends AppException {
  const ValidationException([super.message = '']);
}

class SyncPendingException extends AppException {
  const SyncPendingException([super.message = '']);
}

class UnknownException extends AppException {
  const UnknownException([super.message = '']);
}
