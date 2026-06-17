import 'dart:async';

import 'bootstrap.dart';
import 'core/logging/logger.dart';

/// نقطة الدخول الافتراضية. (لاحقًا: main_dev.dart / main_prod.dart للـ flavors.)
void main() {
  runZonedGuarded<Future<void>>(
    () => bootstrap(),
    (Object error, StackTrace stack) =>
        AppLog.error('Uncaught zone error', error: error, stackTrace: stack),
  );
}
