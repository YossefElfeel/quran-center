import 'package:flutter/material.dart';

/// مدد الحركة الموحّدة.
abstract final class AppDurations {
  const AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration xl = Duration(milliseconds: 500);
}

/// منحنيات الحركة الموحّدة.
abstract final class AppCurves {
  const AppCurves._();

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.decelerate;
}

/// هل المستخدم طالب تقليل الحركة؟ (إعداد نظام إتاحة).
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;
