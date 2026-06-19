import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/tokens.dart';

/// أفاتار موحّد — صورة لو متاحة وإلا أحرف أولى بلون ثابت مشتقّ من الاسم.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.name,
    this.imageUrl,
    this.radius = 22,
    super.key,
  });

  final String name;
  final String? imageUrl;
  final double radius;

  String get _initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) {
      return parts.first.substring(0, 1);
    }
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}';
  }

  Color _color(AppPalette p) {
    final List<Color> options = <Color>[
      p.primary,
      p.accent,
      p.info,
      p.success,
      p.warning,
    ];
    return options[name.hashCode.abs() % options.length];
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final String? imageUrl = this.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl),
      );
    }
    final Color color = _color(p);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: AppOpacity.badgeTint),
      child: Text(
        _initials,
        style: AppTextStyles.titleMd.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
