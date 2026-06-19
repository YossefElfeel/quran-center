import 'package:flutter/material.dart';

/// مقياس الخطوط المسمّى (Cairo) — مصدر واحد لأنماط النص.
///
/// الأحجام/الأوزان مضبوطة لمستخدم عربي غير تقني (واضحة وكبيرة).
abstract final class AppTextStyles {
  const AppTextStyles._();

  static const String fontFamily = 'Cairo';
  static const String quranFamily = 'Amiri';

  static const TextStyle displayLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle titleLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 26 / 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
  );

  /// نص قرآني بالتشكيل (Amiri).
  static TextStyle amiri({double fontSize = 22, Color? color}) => TextStyle(
    fontFamily: quranFamily,
    fontSize: fontSize,
    height: 1.8,
    color: color,
  );

  /// بناء [TextTheme] من المقياس المسمّى لتمريره للثيم.
  static TextTheme textTheme(Color primary, Color secondary) {
    TextStyle p(TextStyle s) => s.copyWith(color: primary);
    return TextTheme(
      displayLarge: p(displayLg),
      displayMedium: p(displayLg.copyWith(fontSize: 28)),
      headlineMedium: p(headlineMd),
      headlineSmall: p(headlineMd.copyWith(fontSize: 20)),
      titleLarge: p(titleLg),
      titleMedium: p(titleMd),
      titleSmall: p(labelLg),
      bodyLarge: p(bodyLg),
      bodyMedium: p(bodyMd),
      bodySmall: bodyMd.copyWith(color: secondary, fontSize: 13),
      labelLarge: p(labelLg),
      labelMedium: labelSm.copyWith(color: secondary),
      labelSmall: labelSm.copyWith(color: secondary),
    );
  }
}
