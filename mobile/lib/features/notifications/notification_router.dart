import '../../app/router/routes.dart';
import '../parent_portal/domain/child_summary.dart';
import 'domain/app_notification.dart';

/// يحوّل إشعارًا لوجهته (مصدره) حسب نوعه + أدوار المستلِم.
///
/// التوجيه بيعتمد على نوع الإشعار ودور المستلِم (نفس النوع ممكن يروح لوجهة مختلفة
/// حسب لو المستلِم معلّم/مشرف/ولي أمر). لولي الأمر بنفتح كارت الطفل مباشرة لو عنده
/// طفل واحد، وإلا قايمة أبنائه. بيرجّع مسار go_router أو null (مفيش وجهة → غير قابل
/// للنقر).
String? notificationRoute(
  AppNotification n,
  List<String> roles, {
  List<ChildSummary> children = const <ChildSummary>[],
}) {
  bool has(String r) => roles.contains(r);
  final bool isStaff = has('admin') || has('super_admin') || has('supervisor');

  // وجهة ولي الأمر لإشعار يخصّ طفلًا: الكارت مباشرة لو طفل واحد، وإلا القايمة.
  String childDestination() {
    if (children.length == 1) {
      return Routes.parentChild(
        children.first.studentPersonId,
        children.first.fullName,
      );
    }
    return Routes.parentChildren;
  }

  // تقييم الحلقة الشهري للمعلّم (أو حلقاته لو الإشعار من غير حلقة).
  String teacherMonthlyEval() => n.circleId == null
      ? Routes.teacherCircles
      : '${Routes.monthlyEval(n.circleId!, 'الحلقة')}'
            '${n.month == null ? '' : '&month=${Uri.encodeComponent(n.month!)}'}';

  switch (n.type) {
    // تقييم/ملاحظة/كارت تقدّم → مصدرها الطفل (لولي الأمر).
    case 'supervisor_eval':
    case 'behavior_note':
    case 'progress_card':
      return childDestination();

    // تعثّر طالب → المعلّم: حلقاته؛ المشرف: شاشة المحتاجين انتباه؛ ولي الأمر: الطفل.
    case 'struggling':
      if (has('teacher')) return Routes.teacherCircles;
      if (isStaff) return Routes.supervisorAttention;
      return childDestination();

    // انتقال حلقة → المشرف: قايمة المراجعات.
    case 'advance':
      if (isStaff) return Routes.supervisorEval;
      return null;

    // تقييم شهري اترجّع للمعلّم → تقييم الحلقة (المعلّم هو اللي يعدّل).
    case 'monthly_eval_returned':
      if (has('teacher')) return teacherMonthlyEval();
      if (isStaff) return Routes.supervisorMonthlyEval;
      return null;

    // تقييمات شهرية ناقصة: نسخة المعلّم فيها circle_id → حلقته؛ نسخة الإدارة
    // من غير حلقة → اعتماد المشرف (حتى لو المستلم معلّم ومشرف في نفس الوقت).
    case 'monthly_eval_missed':
      if (n.circleId != null && has('teacher')) return teacherMonthlyEval();
      if (isStaff) return Routes.supervisorMonthlyEval;
      if (has('teacher')) return Routes.teacherCircles;
      return null;

    case 'development_returned':
      return has('teacher') ? Routes.teacherDevelopment : null;
    case 'excuse_decided':
      return has('teacher') && n.circleId != null
          ? Routes.session(n.circleId!, 'الحلقة')
          : (has('teacher') ? Routes.teacherCircles : null);

    // شكوى متأخّرة → صندوق الشكاوى (المدير/المشرف).
    case 'complaint_overdue':
      if (isStaff) return Routes.complaintsInbox;
      return Routes.complaintsMine;

    // مرشّحون لشهادة → شاشة إصدار الشهادات.
    case 'certificate_candidate':
      if (isStaff) return Routes.issueCertificate;
      return null;

    // اشتراك متأخّر → إدارة الأسر والاشتراكات للأدمن؛ شاشة الاشتراك لولي الأمر؛
    // المشرف (من غير دور ولي أمر) مالوش شاشة اشتراكات.
    case 'subscription_overdue':
      if (has('admin') || has('super_admin')) return Routes.adminSubscriptions;
      if (isStaff && !has('parent')) return null;
      return '/parent/subscription';

    default:
      return null;
  }
}
