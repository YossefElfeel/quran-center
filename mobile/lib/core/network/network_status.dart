import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_status.g.dart';

/// هل الخطأ ده بسبب انقطاع الشبكة؟ → نوزّعه على طابور الإرسال بدل ما نفشل
/// (الأخطاء التانية زي رفض الصلاحية/التحقق لازم تطفو للمستخدم).
bool isOfflineError(Object e) {
  if (e is SocketException || e is TimeoutException || e is HttpException) {
    return true;
  }
  // package:http (ClientException) و supabase بيلفّوا الخطأ في رسالة نصّية.
  final String s = e.toString().toLowerCase();
  return s.contains('socketexception') ||
      s.contains('clientexception') ||
      s.contains('failed host lookup') ||
      s.contains('connection closed') ||
      s.contains('connection reset') ||
      s.contains('connection refused') ||
      s.contains('network is unreachable') ||
      s.contains('xmlhttprequest'); // الويب
}

/// بثّ حالة الاتصال (online=true / offline=false) من connectivity_plus.
/// online لو فيه أي واجهة شبكة غير `none`.
@Riverpod(keepAlive: true)
Stream<bool> connectivityOnline(Ref ref) {
  return Connectivity().onConnectivityChanged.map(
    (List<ConnectivityResult> results) =>
        results.any((ConnectivityResult r) => r != ConnectivityResult.none),
  );
}
