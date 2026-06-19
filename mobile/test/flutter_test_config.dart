import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// إعداد عام لكل الاختبارات: حمّل خط Cairo عشان النصوص العربية (والأرقام
/// العربية-الهندية) تترسم بالخط الفعلي في الـ golden tests بدل المربّعات.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ByteData fontData = await rootBundle.load('assets/fonts/Cairo.ttf');
  final FontLoader loader = FontLoader('Cairo')
    ..addFont(Future<ByteData>.value(fontData));
  await loader.load();
  await testMain();
}
