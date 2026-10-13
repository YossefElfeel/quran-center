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

  if (!Env.hasSupabase) {
    AppLog.warn(
      'Supabase env مش متوفّر — شغّل بـ --dart-define-from-file=env/dev.json',
    );
    runApp(const _MissingConfigurationApp());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    // القيمة publishable key (الصيغة الجديدة sb_publishable_...).
    publishableKey: Env.supabaseAnonKey,
  );

  // حاوية صريحة عشان نفعّل مزامن الطابور (outbox) عند البدء — يفرّغ عمليات
  // الكتابة المؤجّلة أول ما النت يرجع. (اختبارات الـ widget بتعمل ProviderScope
  // بتاعها فمش بتفتح Drift.)
  final ProviderContainer container = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const QuranCenterApp(),
    ),
  );

  // نأجّل تفعيل المزامن (وفتح Drift) لبعد أول إطار عشان ما نعطّلش بداية التشغيل
  // (كان بيسبّب تقطيع في أول لقطة — Skipped frames).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    container.read(outboxSyncProvider);
  });
}

/// بديل واضح بدل شاشة رمادية لو اتبنت نسخة من غير إعدادات الاتصال.
class _MissingConfigurationApp extends StatelessWidget {
  const _MissingConfigurationApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 64,
                    color: Color(0xFF0B8A65),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'إعدادات الاتصال غير مكتملة',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تعذّر بدء التطبيق لأن بيانات الاتصال بالخدمة غير موجودة. '
                    'يرجى تثبيت النسخة المعتمدة أو التواصل مع الدعم.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
