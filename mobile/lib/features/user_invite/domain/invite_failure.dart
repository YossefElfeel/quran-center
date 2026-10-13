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

  /// رسالة للمستخدم فيها السبب + الخطوة الجاية.
  String get message => switch (this) {
    InviteFailure.forbidden => 'الدعوة للأدمن بس',
    InviteFailure.alreadyHasLogin =>
      'الشخص ده عنده حساب دخول بالفعل — خليه يدخل بإيميله، ولو نسي كلمة السر يدوس «نسيت كلمة السر؟» في شاشة الدخول',
    InviteFailure.emailAlreadyRegistered =>
      'الإيميل ده متسجّل بحساب تاني — استخدم إيميل مختلف، أو لو هو نفس الشخص يدوس «نسيت كلمة السر؟»',
    InviteFailure.parentNeedsHousehold =>
      'ولي الأمر لازم يكون في أسرة ومربوط بطفل الأول — كمّل بياناته من «تعديل البيانات / الأسرة» وبعدين ابعت الدعوة',
    InviteFailure.parentNeedsFamilyFlow =>
      'أولياء الأمور بيتضافوا من «ربط أولياء الأمور» الأول، وبعدها تقدر تبعتلهم دعوة',
    InviteFailure.invalidExistingPerson =>
      'الحساب ده مش متاح للدعوة (موقوف أو دوره مختلف) — راجع بياناته من لوحة الإدارة',
    InviteFailure.badRequest => 'اتأكد من الإيميل والاسم والدور وجرّب تاني',
    InviteFailure.linkFailed =>
      'تعذّر إنشاء رابط الدعوة — لو الإيميل ده متسجّل قبل كده استخدم إيميل تاني، وإلا جرّب بعد شوية',
    InviteFailure.unknown =>
      'مش قادرين نبعت الدعوة — اتأكد من البيانات وجرّب تاني',
  };
}
