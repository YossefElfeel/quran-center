import 'dart:developer' as developer;

/// لوج بسيط من غير `print` (avoid_print). **ممنوع تسجيل أي PII**
/// (رقم قومي / موبايل / توكن).
abstract final class AppLog {
  const AppLog._();

  static void info(String message) => developer.log(message, name: 'app');

  static void warn(String message) =>
      developer.log(message, name: 'app', level: 900);

  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      developer.log(
        message,
        name: 'app',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
}
