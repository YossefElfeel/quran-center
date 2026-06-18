/// مسارات التطبيق (ثوابت typed بدل نصوص متناثرة).
abstract final class Routes {
  const Routes._();

  static const String home = '/';
  static const String login = '/login';
  static const String notifications = '/notifications';
  static const String adminCurricula = '/admin/curricula';
  static const String adminWaiting = '/admin/waiting';
  static const String adminSubscriptions = '/admin/subscriptions';

  // مستويات منهج
  static const String levelsPattern = '/admin/curricula/:curriculumId/levels';
  static String levels(String curriculumId, String name) =>
      '/admin/curricula/$curriculumId/levels?name=${Uri.encodeComponent(name)}';

  // حلقات مستوى
  static const String circlesPattern = '/admin/levels/:levelId/circles';
  static String circles(String levelId, String name) =>
      '/admin/levels/$levelId/circles?name=${Uri.encodeComponent(name)}';

  // روستر حلقة (الطلبة المسجّلين)
  static const String rosterPattern = '/admin/circles/:circleId/students';
  static String roster(String circleId, String name) =>
      '/admin/circles/$circleId/students?name=${Uri.encodeComponent(name)}';

  // المعلّم: حلقاته + حصة النهارده
  static const String teacherCircles = '/teacher/circles';
  static const String sessionPattern = '/teacher/session/:circleId';
  static String session(String circleId, String name) =>
      '/teacher/session/$circleId?name=${Uri.encodeComponent(name)}';

  // المشرف: تقييم الحلقات (٣×١٠)
  static const String supervisorEval = '/supervisor/eval';
  static const String supervisorCircleEvalPattern =
      '/supervisor/eval/:circleId';
  static String supervisorCircleEval(String circleId, String name) =>
      '/supervisor/eval/$circleId?name=${Uri.encodeComponent(name)}';

  // المشرف: طابور أعذار الغياب
  static const String supervisorExcuses = '/supervisor/excuses';

  // المشرف: محتاج انتباه (الطلبة المتعثّرين)
  static const String supervisorAttention = '/supervisor/attention';
}
