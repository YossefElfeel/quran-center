/// إعدادات البيئة عبر `--dart-define-from-file=env/dev.json|prod.json`.
/// مفيش أسرار في الكود؛ القيم بتتحقن وقت البناء. anon key لـ Supabase publishable
/// (آمن في الكلاينت)، أما service-role فعمره ما يكون في التطبيق.
abstract final class Env {
  const Env._();

  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static bool get isProd => flavor == 'prod';

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
