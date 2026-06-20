import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../sync/outbox_op.dart';
import '../sync/outbox_store.dart';

part 'local_db.g.dart';

/// طابور عمليات الكتابة المؤجّلة — يفضل على القرص لحد ما يتزامن مع السيرفر.
/// (اسم الكلاس `OutboxEntries` عشان row class المولّد `OutboxEntry` ما يصطدمش
/// مع `OutboxOp` بتاع الدومين.)
class OutboxEntries extends Table {
  TextColumn get id => text()();
  TextColumn get opType => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()(); // epoch ms — ترتيب FIFO
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// كاش "حصة النهارده" لكل حلقة (JSON) — يخلّي الشاشة تفتح أوفلاين بعد إعادة
/// التشغيل، فالمعلّم يكمّل تسجيل (يدخل الطابور) من غير اتصال.
class CachedSessions extends Table {
  TextColumn get circleId => text()();
  TextColumn get payloadJson => text()();
  IntColumn get cachedAt => integer()(); // epoch ms

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{circleId};
}

/// قاعدة البيانات المحلية (Drift) — تنفّذ [OutboxStore] فوق `outbox_entries`
/// + كاش الحصص.
@DriftDatabase(tables: <Type>[OutboxEntries, CachedSessions])
class LocalDb extends _$LocalDb implements OutboxStore {
  LocalDb([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) await m.createTable(cachedSessions);
    },
  );

  // ===== كاش الحصص =====

  Future<void> cacheSession(String circleId, String payloadJson) async {
    await into(cachedSessions).insertOnConflictUpdate(
      CachedSessionsCompanion.insert(
        circleId: circleId,
        payloadJson: payloadJson,
        cachedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<String?> readCachedSession(String circleId) async {
    final CachedSession? row =
        await (select(cachedSessions)
              ..where(($CachedSessionsTable t) => t.circleId.equals(circleId)))
            .getSingleOrNull();
    return row?.payloadJson;
  }

  @override
  Future<void> enqueue(OutboxOp op) async {
    await into(outboxEntries).insert(
      OutboxEntriesCompanion.insert(
        id: op.id,
        opType: op.type.dbValue,
        payloadJson: op.payloadJson,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
      // نفس الـ id = نفس العملية → تجاهل (آمن للتكرار/إعادة الإدخال).
      mode: InsertMode.insertOrIgnore,
    );
  }

  @override
  Future<List<OutboxOp>> pending({int limit = 100}) {
    return (select(outboxEntries)
          ..where(($OutboxEntriesTable t) => t.status.equals('pending'))
          ..orderBy(<OrderClauseGenerator<$OutboxEntriesTable>>[
            ($OutboxEntriesTable t) => OrderingTerm(expression: t.createdAt),
          ])
          ..limit(limit))
        .map(_toOp)
        .get();
  }

  @override
  Future<void> markSynced(String id) async {
    // نجاح → اشطب الصف (مفيش تراكم لا نهائي لعمليات متزامنة).
    await (delete(
      outboxEntries,
    )..where(($OutboxEntriesTable t) => t.id.equals(id))).go();
  }

  @override
  Future<void> markFailed(String id, String error) async {
    await customUpdate(
      'UPDATE outbox_entries SET attempts = attempts + 1, last_error = ? '
      'WHERE id = ?',
      variables: <Variable<Object>>[
        Variable<String>(error),
        Variable<String>(id),
      ],
      updates: <TableInfo<Table, dynamic>>{outboxEntries},
    );
  }

  @override
  Future<void> markDeadLetter(String id, String error) async {
    // فشل نهائي → status='dead' (بتتشال من pending) + سجّل السبب + زوّد العدّاد.
    await customUpdate(
      "UPDATE outbox_entries SET status = 'dead', attempts = attempts + 1, "
      'last_error = ? WHERE id = ?',
      variables: <Variable<Object>>[
        Variable<String>(error),
        Variable<String>(id),
      ],
      updates: <TableInfo<Table, dynamic>>{outboxEntries},
    );
  }

  @override
  Future<int> pendingCount() => _countWhere('pending');

  @override
  Future<int> deadLetterCount() => _countWhere('dead');

  Future<int> _countWhere(String status) async {
    final Expression<int> cnt = outboxEntries.id.count();
    final TypedResult row =
        await (selectOnly(outboxEntries)
              ..addColumns(<Expression<Object>>[cnt])
              ..where(outboxEntries.status.equals(status)))
            .getSingle();
    return row.read(cnt) ?? 0;
  }

  @override
  Future<List<DeadLetterEntry>> deadLetters({int limit = 100}) {
    return (select(outboxEntries)
          ..where(($OutboxEntriesTable t) => t.status.equals('dead'))
          ..orderBy(<OrderClauseGenerator<$OutboxEntriesTable>>[
            ($OutboxEntriesTable t) => OrderingTerm(expression: t.createdAt),
          ])
          ..limit(limit))
        .map(_toDeadLetter)
        .get();
  }

  @override
  Future<void> requeue(String id) async {
    // إعادة المحاولة: ارجع للطابور المعلّق وصفّر العدّاد + امسح آخر خطأ.
    await customUpdate(
      "UPDATE outbox_entries SET status = 'pending', attempts = 0, "
      'last_error = NULL WHERE id = ?',
      variables: <Variable<Object>>[Variable<String>(id)],
      updates: <TableInfo<Table, dynamic>>{outboxEntries},
    );
  }

  @override
  Future<void> discard(String id) async {
    await (delete(
      outboxEntries,
    )..where(($OutboxEntriesTable t) => t.id.equals(id))).go();
  }

  /// بثّ حالة الطابور (معلّق/ميت) — يتحدّث تلقائيًا مع أي تغيير في الجدول،
  /// فمؤشّر المزامنة في القشرة يبقى حيّ من غير invalidate يدوي.
  Stream<SyncStatus> watchSyncStatus() {
    return select(outboxEntries).watch().map((List<OutboxEntry> rows) {
      int pending = 0;
      int dead = 0;
      for (final OutboxEntry r in rows) {
        if (r.status == 'pending') {
          pending++;
        } else if (r.status == 'dead') {
          dead++;
        }
      }
      return SyncStatus(pending: pending, dead: dead);
    });
  }

  DeadLetterEntry _toDeadLetter(OutboxEntry row) => DeadLetterEntry(
    id: row.id,
    type: OutboxOpType.fromDb(row.opType),
    attempts: row.attempts,
    lastError: row.lastError,
  );

  OutboxOp _toOp(OutboxEntry row) => OutboxOp(
    id: row.id,
    type: OutboxOpType.fromDb(row.opType),
    payload: OutboxOp.decodePayload(row.payloadJson),
    attempts: row.attempts,
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'quran_center_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// قاعدة البيانات المحلية كـ singleton عبر التطبيق.
@Riverpod(keepAlive: true)
LocalDb localDb(Ref ref) {
  final LocalDb db = LocalDb();
  ref.onDispose(db.close);
  return db;
}
