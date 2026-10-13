import 'package:riverpod_annotation/riverpod_annotation.dart';

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
