import 'package:flutter/material.dart';

/// ألوان التطبيق (design tokens) — مصدر واحد للألوان، يعتمد عليه كل widget.
abstract final class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1F7A53); // أخضر هادئ
  static const Color primaryDark = Color(0xFF155C3E);
  static const Color accent = Color(0xFFC9A227); // ذهبي
  static const Color background = Color(0xFFF6F7F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color error = Color(0xFFC62828);
  static const Color success = Color(0xFF2E7D32);
  static const Color border = Color(0xFFE3E3DE);
}

/// مقياس المسافات الموحّد.
abstract final class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// أنصاف أقطار الزوايا.
abstract final class AppRadii {
  const AppRadii._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
}

/// مقاسات لمس دنيا (سهولة وصول للمستخدم غير التقني).
abstract final class AppSizes {
  const AppSizes._();

  static const double minTouch = 48;
  static const double primaryButtonHeight = 56;
}
