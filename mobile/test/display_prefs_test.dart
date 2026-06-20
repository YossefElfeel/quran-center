import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/shared/theme/display_prefs.dart';
import 'package:quran_center/shared/theme/tokens.dart';

void main() {
  group('AppTextSize.scale', () {
    test('بترجّع المضاعِفات الصح', () {
      expect(AppTextSize.small.scale, 0.9);
      expect(AppTextSize.normal.scale, 1.0);
      expect(AppTextSize.large.scale, 1.15);
      expect(AppTextSize.xlarge.scale, 1.3);
    });
  });

  group('combinedTextScaler', () {
    test('عادي + بدون مقياس نظام = بدون تكبير', () {
      final TextScaler ts = combinedTextScaler(
        TextScaler.noScaling,
        AppTextSize.normal,
      );
      expect(ts.scale(10), closeTo(10, 0.001));
    });

    test('بيضرب مقياس النظام في اختيار المستخدم', () {
      final TextScaler ts = combinedTextScaler(
        const TextScaler.linear(1.0),
        AppTextSize.large,
      );
      expect(ts.scale(100), closeTo(115, 0.001));
    });

    test('بيحدّ الأعلى عند 2.0 (يمنع الكسر في التخطيط)', () {
      final TextScaler ts = combinedTextScaler(
        const TextScaler.linear(2.0), // نظام كبير
        AppTextSize.xlarge, // ×1.3 = 2.6
      );
      expect(ts.scale(10), closeTo(20, 0.001));
    });

    test('بيحدّ الأدنى عند 0.85', () {
      final TextScaler ts = combinedTextScaler(
        const TextScaler.linear(0.5),
        AppTextSize.small, // ×0.9 = 0.45
      );
      expect(ts.scale(100), closeTo(85, 0.001));
    });
  });

  group('لوحات التباين العالي', () {
    test('الفاتح: نصّ أسود نقي ويختلف عن اللوحة العادية', () {
      expect(AppPalette.highContrastLight.textPrimary, const Color(0xFF000000));
      expect(
        AppPalette.highContrastLight.textPrimary,
        isNot(AppPalette.light.textPrimary),
      );
      // حدود أوضح من العادية.
      expect(
        AppPalette.highContrastLight.border,
        isNot(AppPalette.light.border),
      );
    });

    test('الداكن: نصّ أبيض نقي على خلفية سوداء', () {
      expect(AppPalette.highContrastDark.textPrimary, const Color(0xFFFFFFFF));
      expect(AppPalette.highContrastDark.background, const Color(0xFF000000));
    });
  });
}
