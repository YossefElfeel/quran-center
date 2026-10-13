/// مسار شاشة الاشتراك (وجهة بوابة ولي الأمر).
const String parentSubscriptionRoute = '/parent/subscription';

const List<String> _staffRoles = <String>[
  'admin',
  'super_admin',
  'teacher',
  'supervisor',
];

/// بوابة كارت الطفل لولي الأمر: بترجّع مسار التحويل أو null (يكمّل).
///
/// بنحوّل لشاشة الاشتراك **بس** لما السيرفر يقول صراحةً إن الاشتراك مش نشط.
/// أي خطأ (أوفلاين/مهلة/غير معروف) بيعدّي ولي الأمر للكارت المتخزّن بدل ما
/// يقفله بره — السيرفر (RLS) هو الحارس الحقيقي للبيانات.
Future<String?> parentChildGateRedirect({
  required Future<List<String>> Function() roles,
  required Future<bool> Function() subscriptionActive,
}) async {
  try {
    final List<String> r = await roles();
    if (!r.contains('parent') || r.any(_staffRoles.contains)) return null;
    return await subscriptionActive() ? null : parentSubscriptionRoute;
  } catch (_) {
    return null;
  }
}
