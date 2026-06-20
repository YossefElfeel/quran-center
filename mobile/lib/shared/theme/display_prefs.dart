import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تفضيلات العرض (إتاحة الوصول): حجم الخطّ + التباين العالي — محفوظة محليًا.

/// خيارات حجم الخطّ (مضاعِف يتركّب فوق مقياس النظام).
enum AppTextSize { small, normal, large, xlarge }

extension AppTextSizeX on AppTextSize {
  double get scale => switch (this) {
    AppTextSize.small => 0.9,
    AppTextSize.normal => 1.0,
    AppTextSize.large => 1.15,
    AppTextSize.xlarge => 1.3,
  };
}

/// حجم الخطّ المختار — محفوظ في SharedPreferences (من غير codegen).
class TextSizeNotifier extends Notifier<AppTextSize> {
  static const String _key = 'text_size';

  @override
  AppTextSize build() {
    _load();
    return AppTextSize.normal;
  }

  void _load() {
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      final String? v = prefs.getString(_key);
      if (v != null) {
        state = AppTextSize.values.firstWhere(
          (AppTextSize e) => e.name == v,
          orElse: () => AppTextSize.normal,
        );
      }
    });
  }

  Future<void> set(AppTextSize size) async {
    state = size;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, size.name);
  }
}

final NotifierProvider<TextSizeNotifier, AppTextSize> textSizeProvider =
    NotifierProvider<TextSizeNotifier, AppTextSize>(TextSizeNotifier.new);

/// تباين عالي (للوصول) — يبدّل للوحة ألوان أوضح. محفوظ محليًا.
class HighContrastNotifier extends Notifier<bool> {
  static const String _key = 'high_contrast';

  @override
  bool build() {
    _load();
    return false;
  }

  void _load() {
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      final bool? v = prefs.getBool(_key);
      if (v != null) state = v;
    });
  }

  Future<void> set(bool on) async {
    state = on;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, on);
  }
}

final NotifierProvider<HighContrastNotifier, bool> highContrastProvider =
    NotifierProvider<HighContrastNotifier, bool>(HighContrastNotifier.new);

/// المقياس النهائي للنص = مقياس النظام × اختيار المستخدم، مع حدّ آمن.
TextScaler combinedTextScaler(TextScaler system, AppTextSize size) {
  final double osFactor = system.scale(1);
  final double combined = (osFactor * size.scale).clamp(0.85, 2.0);
  return TextScaler.linear(combined);
}
