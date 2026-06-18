/// مسارات التطبيق (ثوابت typed بدل نصوص متناثرة).
abstract final class Routes {
  const Routes._();

  static const String home = '/';
  static const String login = '/login';
  static const String notifications = '/notifications';
  static const String adminCurricula = '/admin/curricula';
  static const String adminWaiting = '/admin/waiting';
  static const String adminSubscriptions = '/admin/subscriptions';
  static const String adminGuardians = '/admin/guardians';
  static const String householdMembersPattern =
      '/admin/household/:householdId/members';
  static String householdMembers(String householdId, String name) =>
      '/admin/household/$householdId/members?name=${Uri.encodeComponent(name)}';

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

  // المعلّم: خطة الشهر للحلقة
  static const String monthlyPlanPattern =
      '/teacher/circle/:circleId/monthly-plan';
  static String monthlyPlan(String circleId, String name) =>
      '/teacher/circle/$circleId/monthly-plan?name=${Uri.encodeComponent(name)}';

  // المعلّم: ملفّه وتطوّره — والمشرف: اعتماد التطوّر
  static const String teacherDevelopment = '/teacher/development';
  static const String teacherProfile = '/teacher/profile';
  static const String supervisorDevApproval = '/supervisor/development';

  // التقييم الشهري للطالب: المعلّم يؤلّف، المشرف يعتمد
  static const String monthlyEvalPattern =
      '/teacher/circle/:circleId/monthly-eval';
  static String monthlyEval(String circleId, String name) =>
      '/teacher/circle/$circleId/monthly-eval?name=${Uri.encodeComponent(name)}';
  static const String supervisorMonthlyEval = '/supervisor/monthly-eval';

  // إصدار الشهادات (المشرف/الأدمن)
  static const String issueCertificate = '/issue-certificate';

  // تقييمات المحفّظين (المدير/المشرف)
  static const String teacherRatings = '/teacher-ratings';

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

  // ولي الأمر: أولاده + كارت الطفل
  static const String parentChildren = '/parent/children';
  static const String parentChildPattern = '/parent/child/:studentId';
  static String parentChild(String studentId, String name) =>
      '/parent/child/$studentId?name=${Uri.encodeComponent(name)}';

  // الشكاوى: المستخدم + صندوق المدير
  static const String complaintsMine = '/complaints';
  static const String complaintsInbox = '/admin/complaints';

  // لوحة الشرف (متفوّقو الشهر)
  static const String honorBoard = '/honor-board';

  // الكورسات المجانية
  static const String courses = '/courses';

  // المسابقات
  static const String competitions = '/competitions';
  static const String competitionDetailPattern = '/competitions/:id';
  static String competitionDetail(String id, String name) =>
      '/competitions/$id?name=${Uri.encodeComponent(name)}';
  static const String competitionResultsPattern = '/competitions/:id/results';
  static String competitionResults(String id, String name) =>
      '/competitions/$id/results?name=${Uri.encodeComponent(name)}';

  // معاينة شهادة PDF
  static const String certificatePreviewPattern = '/certificate/preview';
  static String certificatePreview(
    String name,
    String kindLabel,
    String dateLabel,
  ) =>
      '/certificate/preview?name=${Uri.encodeComponent(name)}'
      '&kind=${Uri.encodeComponent(kindLabel)}'
      '&date=${Uri.encodeComponent(dateLabel)}';
}
