import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختيار المستخدم للثيم. amoled = داكن بخلفية سوداء نقيّة.
enum AppThemeChoice { system, light, dark, amoled }

extension AppThemeChoiceX on AppThemeChoice {
  /// هل ده وضع داكن صريح؟ (مش system)
  bool get isExplicitDark =>
      this == AppThemeChoice.dark || this == AppThemeChoice.amoled;
}

/// يحفظ/يقرأ اختيار الثيم محليًا (SharedPreferences) — بدون codegen.
class ThemeModeNotifier extends Notifier<AppThemeChoice> {
  static const String _key = 'theme_choice';

  @override
  AppThemeChoice build() {
    // قيمة ابتدائية لحد ما القراءة من القرص تخلص.
    unawaitedLoad();
    return AppThemeChoice.system;
  }

  void unawaitedLoad() {
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      final String? v = prefs.getString(_key);
      if (v != null) {
        state = AppThemeChoice.values.firstWhere(
          (AppThemeChoice e) => e.name == v,
          orElse: () => AppThemeChoice.system,
        );
      }
    });
  }

  Future<void> set(AppThemeChoice choice) async {
    state = choice;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, choice.name);
  }
}

final NotifierProvider<ThemeModeNotifier, AppThemeChoice> themeChoiceProvider =
    NotifierProvider<ThemeModeNotifier, AppThemeChoice>(ThemeModeNotifier.new);

/// [ThemeMode] المقابل للاختيار (amoled بيتعامل كـ dark + ثيم منفصل في app.dart).
ThemeMode themeModeFor(AppThemeChoice c) {
  switch (c) {
    case AppThemeChoice.system:
      return ThemeMode.system;
    case AppThemeChoice.light:
      return ThemeMode.light;
    case AppThemeChoice.dark:
    case AppThemeChoice.amoled:
      return ThemeMode.dark;
  }
}
