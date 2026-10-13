import 'package:quran_center/l10n/generated/app_localizations.dart';
import '../../core/error/app_exception.dart';

extension LocalizedException on AppException {
  String localizedMessage(AppL10n l) {
    final AppErrorReason? reason = this.reason;
    if (reason != null) return reason.label(l);
    if (message.isNotEmpty) return message;
    return switch (this) {
      NetworkException() => l.noConnection,
      PermissionDeniedException() => l.exceptionPermissionDenied,
      NotFoundException() => l.exceptionNotFound,
      ValidationException() => l.exceptionValidation,
      SyncPendingException() => l.exceptionSyncPending,
      UnknownException() => l.exceptionUnknown,
    };
  }
}

extension AppErrorReasonLabel on AppErrorReason {
  String label(AppL10n l) => switch (this) {
    AppErrorReason.accountSuspended => l.errAccountSuspended,
    AppErrorReason.invalidCredentials => l.errInvalidCredentials,
    AppErrorReason.tooManyAttempts => l.errTooManyAttempts,
    AppErrorReason.signInFailed => l.errSignInFailed,
    AppErrorReason.resetLinkNotConfigured => l.errResetLinkNotConfigured,
    AppErrorReason.fileTooLarge => l.errFileTooLarge,
    AppErrorReason.sessionExpired => l.errSessionExpired,
    AppErrorReason.fileUploadFailed => l.errFileUploadFailed,
    AppErrorReason.documentSaveFailed => l.errDocumentSaveFailed,
    AppErrorReason.mediaConsentRequired => l.errMediaConsentRequired,
    AppErrorReason.mediaUploadFailed => l.errMediaUploadFailed,
    AppErrorReason.mediaUrlFailed => l.errMediaUrlFailed,
    AppErrorReason.nationalIdTaken => l.errNationalIdTaken,
    AppErrorReason.nationalIdLength => l.enrNationalIdLengthError,
    AppErrorReason.alreadyInHousehold => l.errAlreadyInHousehold,
  };
}
