import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// منطق إعادة التوجيه (redirect). placeholder في Phase 0.
///
/// Phase 1+: يقرأ الجلسة + الدور + حالة الاشتراك:
/// - غير مسجّل → /login
/// - مسجّل → landing حسب الدور (/teacher/today، /supervisor، /parent، /admin)
/// - ولي أمر + اشتراك != active → /subscription/pay (مع allowlist)
String? guardRedirect(Ref ref, GoRouterState state) {
  return null;
}
