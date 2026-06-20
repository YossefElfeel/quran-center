import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Hero يحترم إعداد "تقليل الحركة": بيلفّ العنصر في [Hero] بس لو الحركة مسموحة،
/// وإلا بيرجّع العنصر زيّ ما هو (من غير طيران بين الشاشات).
class AppHero extends StatelessWidget {
  const AppHero({required this.tag, required this.child, super.key});

  final Object tag;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      reduceMotion(context) ? child : Hero(tag: tag, child: child);
}
