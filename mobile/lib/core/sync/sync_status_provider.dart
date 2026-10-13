import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/local_db.dart';
import 'outbox_store.dart';

part 'sync_status_provider.g.dart';

/// بثّ حيّ لحالة طابور المزامنة (معلّق/ميت) — يغذّي مؤشّر القشرة وشيت الحالة.
/// يتحدّث تلقائيًا مع أي تغيير في الطابور (Drift watch).
@riverpod
Stream<SyncStatus> syncStatus(Ref ref) {
  return ref.watch(localDbProvider).watchSyncStatus();
}

/// عدد السجلات المعلّقة (في انتظار المزامنة) — لشارة زر المزامنة في رئيسية
/// المعلّم. صفر لحد ما الطابور يتحمّل.
@riverpod
int syncPendingCount(Ref ref) =>
    ref.watch(syncStatusProvider).asData?.value.pending ?? 0;

/// وقت آخر مزامنة فعلية (الطابور كان فيه معلّق واتفرّغ) — محفوظ على الجهاز
/// عشان شيت الحالة يعرض "آخر مزامنة". null = لسه مفيش مزامنة متسجّلة.
@Riverpod(keepAlive: true)
class LastSyncAt extends _$LastSyncAt {
  static const String _key = 'last_sync_at';

  @override
  DateTime? build() {
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? ms = prefs.getInt(_key);
      if (ms != null && ref.mounted && state == null) {
        state = DateTime.fromMillisecondsSinceEpoch(ms);
      }
    } catch (_) {
      // التخزين مش متاح (اختبارات مثلًا) — نكتفي بالقيمة في الذاكرة.
    }
  }

  Future<void> markNow() async {
    final DateTime now = DateTime.now();
    state = now;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, now.millisecondsSinceEpoch);
    } catch (_) {
      // نفس اللي فوق — مش حرج.
    }
  }
}
