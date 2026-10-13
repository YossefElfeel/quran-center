import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../core/error/app_exception.dart';
import '../../../shared/presentation/exception_message.dart';
import '../domain/invite_failure.dart';

extension InviteFailureLabel on InviteFailure {
  /// رسالة للمستخدم فيها السبب + الخطوة الجاية.
  String message(AppL10n l) => switch (this) {
    InviteFailure.forbidden => l.invFailureForbidden,
    InviteFailure.alreadyHasLogin => l.invFailureAlreadyHasLogin,
    InviteFailure.emailAlreadyRegistered => l.invFailureEmailAlreadyRegistered,
    InviteFailure.parentNeedsHousehold => l.invFailureParentNeedsHousehold,
    InviteFailure.parentNeedsFamilyFlow => l.invFailureParentNeedsFamilyFlow,
    InviteFailure.invalidExistingPerson => l.invFailureInvalidExistingPerson,
    InviteFailure.badRequest => l.invFailureBadRequest,
    InviteFailure.linkFailed => l.invFailureLinkFailed,
    InviteFailure.linkMissing => l.invFailureLinkMissing,
    InviteFailure.unknown => l.invFailureUnknown,
  };
}

/// رسالة فشل الدعوة للمستخدم من الاستثناء، أو `null` لو الخطأ مش معروف.
String? inviteErrorMessage(Object error, AppL10n l) => switch (error) {
  InviteException(:final InviteFailure failure) => failure.message(l),
  AppException() => error.localizedMessage(l),
  _ => null,
};
