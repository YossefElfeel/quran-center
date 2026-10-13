import 'package:quran_center/l10n/generated/app_localizations.dart';
import '../../core/error/app_exception.dart';

extension LocalizedException on AppException {
  String localizedMessage(AppL10n l) => message.isNotEmpty
      ? message
      : switch (this) {
          NetworkException() => l.noConnection,
          PermissionDeniedException() => l.exceptionPermissionDenied,
          NotFoundException() => l.exceptionNotFound,
          ValidationException() => l.exceptionValidation,
          SyncPendingException() => l.exceptionSyncPending,
          UnknownException() => l.exceptionUnknown,
        };
}
