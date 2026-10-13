/// أسباب فشل الدعوة المعروفة (من ردود Edge Function `invite-user`).
enum InviteFailure {
  /// 403 — النداء مش من أدمن.
  forbidden,

  /// 409 "Person already has a login".
  alreadyHasLogin,

  /// الإيميل متسجّل بحساب تاني (Supabase Auth `email_exists`).
  emailAlreadyRegistered,

  /// 400 "Parent needs a household and child link".
  parentNeedsHousehold,

  /// 400 "Create parents through the family flow".
  parentNeedsFamilyFlow,

  /// 400 "Invalid existing person" — موقوف/قاصر/دوره مختلف.
  invalidExistingPerson,

  /// 400 "Bad Request" — إيميل/اسم/دور غير صالح.
  badRequest,

  /// 500 "invite link failed" — غالبًا الإيميل متسجّل قبل كده.
  linkFailed,

  /// الحساب اتعمل لكن الرد مرجّعش رابط الدعوة.
  linkMissing,

  unknown;

  /// يصنّف الرد من الـ status + نص الجسم.
  static InviteFailure fromResponse(int status, Object? details) {
    final String body = (details ?? '').toString().toLowerCase();
    if (body.contains('already been registered') ||
        body.contains('already registered') ||
        body.contains('email_exists') ||
        body.contains('email exists')) {
      return InviteFailure.emailAlreadyRegistered;
    }
    if (status == 403) return InviteFailure.forbidden;
    if (status == 409 || body.contains('already has a login')) {
      return InviteFailure.alreadyHasLogin;
    }
    if (body.contains('needs a household')) {
      return InviteFailure.parentNeedsHousehold;
    }
    if (body.contains('family flow')) {
      return InviteFailure.parentNeedsFamilyFlow;
    }
    if (body.contains('invalid existing person')) {
      return InviteFailure.invalidExistingPerson;
    }
    if (status == 400) return InviteFailure.badRequest;
    if (body.contains('invite link failed')) return InviteFailure.linkFailed;
    return InviteFailure.unknown;
  }
}

/// استثناء typed بيحمل سبب فشل الدعوة — الرسالة بتتعمل في الـ presentation.
class InviteException implements Exception {
  const InviteException(this.failure);

  final InviteFailure failure;

  @override
  String toString() => 'InviteException: ${failure.name}';
}
