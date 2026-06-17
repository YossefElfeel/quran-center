import 'package:flutter/widgets.dart';

/// سياسة الحركة في التطبيق:
/// - أزمنة قصيرة، **one-shot** بس (مفيش لوب لانهائي / repeat).
/// - احترام reduced-motion: لو المستخدم مفعّلها → الحركة تبقى لحظية.
abstract final class Motion {
  const Motion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);

  /// يرجّع [Duration.zero] لو المستخدم مفعّل reduce-motion.
  static Duration of(BuildContext context, Duration duration) {
    final bool reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return reduce ? Duration.zero : duration;
  }
}
