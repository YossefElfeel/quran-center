/// هرم استثناءات التطبيق. الـ repositories بتمسك أخطاء Supabase/الشبكة
/// وتحوّلها لواحدة من دول (رفض RLS → [PermissionDeniedException] مش crash).
sealed class AppException implements Exception {
  const AppException(this.message, {this.reason});

  /// رسالة خام (من السيرفر مثلًا). للعرض استخدم `localizedMessage(l)` في
  /// طبقة العرض — بتفضّل [reason] لو موجود.
  final String message;

  /// سبب معروف للخطأ بيتحوّل لنص مترجم في طبقة العرض (الـ domain/data مايعرفوش
  /// النصوص).
  final AppErrorReason? reason;

  @override
  String toString() =>
      '$runtimeType: ${reason == null ? message : reason!.name}';
}

/// أسباب أخطاء معروفة بترميها الـ repositories — النص بيتحدد في
/// `shared/presentation/exception_message.dart`.
enum AppErrorReason {
  accountSuspended,
  invalidCredentials,
  tooManyAttempts,
  signInFailed,
  resetLinkNotConfigured,
  fileTooLarge,
  sessionExpired,
  fileUploadFailed,
  documentSaveFailed,
  mediaConsentRequired,
  mediaUploadFailed,
  mediaUrlFailed,
  nationalIdTaken,
  nationalIdLength,
  alreadyInHousehold,
}

class NetworkException extends AppException {
  const NetworkException([super.message = '']);
  const NetworkException.reason(AppErrorReason reason)
    : super('', reason: reason);
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException([super.message = '']);
  const PermissionDeniedException.reason(AppErrorReason reason)
    : super('', reason: reason);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = '']);
  const NotFoundException.reason(AppErrorReason reason)
    : super('', reason: reason);
}

class ValidationException extends AppException {
  const ValidationException([super.message = '']);
  const ValidationException.reason(AppErrorReason reason)
    : super('', reason: reason);
}

class SyncPendingException extends AppException {
  const SyncPendingException([super.message = '']);
  const SyncPendingException.reason(AppErrorReason reason)
    : super('', reason: reason);
}

class UnknownException extends AppException {
  const UnknownException([super.message = '']);
  const UnknownException.reason(AppErrorReason reason)
    : super('', reason: reason);
}
