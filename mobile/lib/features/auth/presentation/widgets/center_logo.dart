import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';

/// شعار الدار (نفس رسمة `web/public/logo.svg`: مصحف مفتوح على مربّع أخضر)
/// مرسوم بـ CustomPainter — من غير أصول صور أو مكتبة SVG.
class CenterLogo extends StatelessWidget {
  const CenterLogo({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Semantics(
      image: true,
      label: AppL10n.of(context).authCenterLogo,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _CenterLogoPainter(
            background: p.primary,
            foreground: p.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _CenterLogoPainter extends CustomPainter {
  const _CenterLogoPainter({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    // الرسمة الأصلية على شبكة 64×64.
    final double s = size.shortestSide / 64;
    canvas.scale(s);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 64, 64),
        const Radius.circular(14),
      ),
      Paint()..color = background,
    );
    final Paint stroke = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    final Path book = Path()
      ..moveTo(32, 17)
      ..cubicTo(24, 13, 17, 13, 9, 16)
      ..lineTo(9, 45)
      ..cubicTo(17, 42, 24, 42, 32, 46)
      ..cubicTo(40, 42, 47, 42, 55, 45)
      ..lineTo(55, 16)
      ..cubicTo(47, 13, 40, 13, 32, 17)
      ..close()
      ..moveTo(32, 17)
      ..lineTo(32, 46)
      ..moveTo(16, 25)
      ..lineTo(25, 25)
      ..moveTo(16, 32)
      ..lineTo(25, 32)
      ..moveTo(39, 25)
      ..lineTo(48, 25)
      ..moveTo(39, 32)
      ..lineTo(48, 32);
    canvas.drawPath(book, stroke);
  }

  @override
  bool shouldRepaint(_CenterLogoPainter old) =>
      old.background != background || old.foreground != foreground;
}
