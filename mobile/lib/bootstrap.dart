import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/logging/logger.dart';

/// تهيئة التطبيق وتشغيله جوّا ProviderScope مع التقاط أخطاء الـ framework.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLog.error(
      'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runApp(const ProviderScope(child: QuranCenterApp()));
}
