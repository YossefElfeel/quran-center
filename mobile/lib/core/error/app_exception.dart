/// هرم استثناءات التطبيق. الـ repositories بتمسك أخطاء Supabase/الشبكة
/// وتحوّلها لواحدة من دول (رفض RLS → [PermissionDeniedException] مش crash).
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'مفيش اتصال بالنت']);
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException([super.message = 'الصلاحية مرفوضة']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'مش موجود']);
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'بيانات غير صحيحة']);
}

class SyncPendingException extends AppException {
  const SyncPendingException([super.message = 'لسه في انتظار المزامنة']);
}

class UnknownException extends AppException {
  const UnknownException([super.message = 'حصل خطأ غير متوقّع']);
}
