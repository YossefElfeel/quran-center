/// مسارات التطبيق (ثوابت typed بدل نصوص متناثرة).
abstract final class Routes {
  const Routes._();

  static const String home = '/';
  static const String login = '/login';
  static const String adminCurricula = '/admin/curricula';

  // مستويات منهج
  static const String levelsPattern = '/admin/curricula/:curriculumId/levels';
  static String levels(String curriculumId, String name) =>
      '/admin/curricula/$curriculumId/levels?name=${Uri.encodeComponent(name)}';

  // حلقات مستوى
  static const String circlesPattern = '/admin/levels/:levelId/circles';
  static String circles(String levelId, String name) =>
      '/admin/levels/$levelId/circles?name=${Uri.encodeComponent(name)}';
}
