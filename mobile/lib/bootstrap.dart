import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/env/env.dart';
import 'core/logging/logger.dart';
import 'features/session/data/session_sync.dart';

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

  if (Env.hasSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // القيمة publishable key (الصيغة الجديدة sb_publishable_...).
      publishableKey: Env.supabaseAnonKey,
    );
  } else {
    AppLog.warn(
      'Supabase env مش متوفّر — شغّل بـ --dart-define-from-file=env/dev.json',
    );
  }

  // حاوية صريحة عشان نفعّل مزامن الطابور (outbox) عند البدء — يفرّغ عمليات
  // الكتابة المؤجّلة أول ما النت يرجع. (اختبارات الـ widget بتعمل ProviderScope
  // بتاعها فمش بتفتح Drift.)
  final ProviderContainer container = ProviderContainer();
  container.read(outboxSyncProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const QuranCenterApp(),
    ),
  );
}
