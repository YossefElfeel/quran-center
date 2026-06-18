import '../../features/progress_engine/domain/progress_engine.dart';

/// إعدادات النظام اللي السوبر أدمن بيضبطها (system_settings) ويقراها التطبيق.
/// أي مفتاح مفقود بيرجع لـ default من محرّك الحفظ — عشان مايكسرش لو الإعداد ناقص.
class AppSettings {
  const AppSettings({
    required this.passThreshold,
    required this.struggleThreshold,
    required this.subscriptionAmount,
    required this.graceDays,
    required this.circleMaxSize,
  });

  factory AppSettings.fromMap(Map<String, Object?> m) => AppSettings(
    passThreshold: _asInt(
      m['daily_pass_threshold'],
      ProgressEngine.defaultPassThreshold,
    ),
    struggleThreshold: _asInt(
      m['struggle_failed_attempts'],
      ProgressEngine.defaultStruggleThreshold,
    ),
    subscriptionAmount: _asNum(m['subscription_amount_egp'], 10),
    graceDays: _asInt(m['subscription_grace_days'], 7),
    circleMaxSize: _asInt(m['circle_max_size'], 30),
  );

  /// قيم افتراضية نقية (تستخدمها الـ providers كـ fallback أثناء التحميل/الخطأ).
  static const AppSettings defaults = AppSettings(
    passThreshold: ProgressEngine.defaultPassThreshold,
    struggleThreshold: ProgressEngine.defaultStruggleThreshold,
    subscriptionAmount: 10,
    graceDays: 7,
    circleMaxSize: 30,
  );

  final int passThreshold;
  final int struggleThreshold;
  final num subscriptionAmount;
  final int graceDays;
  final int circleMaxSize;

  static int _asInt(Object? v, int fallback) => v is num
      ? v.toInt()
      : (v is String ? int.tryParse(v) ?? fallback : fallback);

  static num _asNum(Object? v, num fallback) =>
      v is num ? v : (v is String ? num.tryParse(v) ?? fallback : fallback);
}
