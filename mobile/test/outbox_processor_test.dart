import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/core/sync/outbox_op.dart';
import 'package:quran_center/core/sync/outbox_processor.dart';
import 'package:quran_center/core/sync/outbox_store.dart';

/// مخزن طابور في الذاكرة لاختبار المعالج بدون Drift/sqlite.
class _FakeStore implements OutboxStore {
  final Map<String, _Entry> _m = <String, _Entry>{};
  int _seq = 0;

  @override
  Future<void> enqueue(OutboxOp op) async {
    // insert-or-ignore على id (آمن للتكرار).
    _m.putIfAbsent(op.id, () => _Entry(op, _seq++));
  }

  @override
  Future<List<OutboxOp>> pending({int limit = 100}) async {
    final List<_Entry> es =
        _m.values.where((_Entry e) => e.status == 'pending').toList()
          ..sort((_Entry a, _Entry b) => a.seq.compareTo(b.seq));
    return es
        .take(limit)
        .map(
          (_Entry e) => OutboxOp(
            id: e.op.id,
            type: e.op.type,
            payload: e.op.payload,
            attempts: e.attempts,
          ),
        )
        .toList();
  }

  @override
  Future<void> markSynced(String id) async => _m[id]?.status = 'synced';

  @override
  Future<void> markFailed(String id, String error) async {
    final _Entry? e = _m[id];
    if (e != null) e.attempts++;
  }

  @override
  Future<int> pendingCount() async =>
      _m.values.where((_Entry e) => e.status == 'pending').length;
}

class _Entry {
  _Entry(this.op, this.seq);
  final OutboxOp op;
  final int seq;
  String status = 'pending';
  int attempts = 0;
}

OutboxOp _op(String id) => OutboxOp(
  id: id,
  type: OutboxOpType.attendanceMark,
  payload: <String, dynamic>{'enrollment_id': id},
);

void main() {
  group('OutboxOp', () {
    test('payload يعمل round-trip عبر JSON', () {
      const OutboxOp op = OutboxOp(
        id: 'k1',
        type: OutboxOpType.tasmeeRecord,
        payload: <String, dynamic>{'score': 8, 'passed': true, 'name': 'محمد'},
      );
      final Map<String, dynamic> back = OutboxOp.decodePayload(op.payloadJson);
      expect(back['score'], 8);
      expect(back['passed'], true);
      expect(back['name'], 'محمد');
    });

    test('OutboxOpType round-trip db ↔ enum', () {
      for (final OutboxOpType t in OutboxOpType.values) {
        expect(OutboxOpType.fromDb(t.dbValue), t);
      }
    });
  });

  group('OutboxProcessor.flush', () {
    test('يفرّغ كل المعلّق بترتيب FIFO ويعلّمه synced', () async {
      final _FakeStore store = _FakeStore();
      await store.enqueue(_op('a'));
      await store.enqueue(_op('b'));
      await store.enqueue(_op('c'));
      final List<String> sent = <String>[];
      final OutboxProcessor p = OutboxProcessor(store, (OutboxOp op) async {
        sent.add(op.id);
      });

      await p.flush();

      expect(sent, <String>['a', 'b', 'c']);
      expect(await store.pendingCount(), 0);
    });

    test('يقف عند أول فشل ويحافظ على ترتيب الباقي (مايتخطّاش)', () async {
      final _FakeStore store = _FakeStore();
      await store.enqueue(_op('a'));
      await store.enqueue(_op('b'));
      await store.enqueue(_op('c'));
      final List<String> sent = <String>[];
      final OutboxProcessor p = OutboxProcessor(store, (OutboxOp op) async {
        if (op.id == 'b') throw const SocketLikeError();
        sent.add(op.id);
      });

      await p.flush();

      // a اتبعت، b فشل ووقف، c ماوصلش.
      expect(sent, <String>['a']);
      expect(await store.pendingCount(), 2); // b + c لسه معلّقين
    });

    test('بعد رجوع النت إعادة flush بتكمّل من المتعثّر (idempotent)', () async {
      final _FakeStore store = _FakeStore();
      await store.enqueue(_op('a'));
      await store.enqueue(_op('b'));
      bool failOnce = true;
      final List<String> sent = <String>[];
      final OutboxProcessor p = OutboxProcessor(store, (OutboxOp op) async {
        if (op.id == 'a' && failOnce) {
          failOnce = false;
          throw const SocketLikeError();
        }
        sent.add(op.id);
      });

      await p.flush(); // a يفشل → يقف
      expect(sent, isEmpty);
      expect(await store.pendingCount(), 2);

      await p.flush(); // النت رجع → a ثم b
      expect(sent, <String>['a', 'b']);
      expect(await store.pendingCount(), 0);
    });

    test(
      'enqueue لنفس الـ id مرّتين = عملية واحدة (insert-or-ignore)',
      () async {
        final _FakeStore store = _FakeStore();
        await store.enqueue(_op('dup'));
        await store.enqueue(_op('dup'));
        expect(await store.pendingCount(), 1);
      },
    );
  });
}

/// خطأ تجريبي يحاكي قطع الشبكة (المعالج بيتعامل مع أي throw كفشل).
class SocketLikeError implements Exception {
  const SocketLikeError();
}
