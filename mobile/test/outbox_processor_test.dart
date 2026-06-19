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
  Future<void> markSynced(String id) async => _m.remove(id);

  @override
  Future<void> markFailed(String id, String error) async {
    final _Entry? e = _m[id];
    if (e != null) e.attempts++;
  }

  @override
  Future<void> markDeadLetter(String id, String error) async {
    final _Entry? e = _m[id];
    if (e != null) {
      e.attempts++;
      e.status = 'dead';
    }
  }

  @override
  Future<int> pendingCount() async =>
      _m.values.where((_Entry e) => e.status == 'pending').length;

  int get deadCount => _m.values.where((_Entry e) => e.status == 'dead').length;
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

/// خطأ يحاكي قطع الشبكة (عابر).
class SocketLikeError implements Exception {
  const SocketLikeError();
}

/// خطأ يحاكي رفض السيرفر (نهائي — مش هيتحسّن بإعادة المحاولة).
class TerminalError implements Exception {
  const TerminalError();
}

bool _isTransient(Object e) => e is SocketLikeError;

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
      final OutboxProcessor p = OutboxProcessor(
        store,
        (OutboxOp op) async => sent.add(op.id),
        isTransient: _isTransient,
      );

      await p.flush();

      expect(sent, <String>['a', 'b', 'c']);
      expect(await store.pendingCount(), 0);
    });

    test('فشل عابر بيوقف ويحافظ على ترتيب الباقي (مايتخطّاش)', () async {
      final _FakeStore store = _FakeStore();
      await store.enqueue(_op('a'));
      await store.enqueue(_op('b'));
      await store.enqueue(_op('c'));
      final List<String> sent = <String>[];
      final OutboxProcessor p = OutboxProcessor(store, (OutboxOp op) async {
        if (op.id == 'b') throw const SocketLikeError();
        sent.add(op.id);
      }, isTransient: _isTransient);

      await p.flush();

      // a اتبعت، b فشل عابر ووقف، c ماوصلش.
      expect(sent, <String>['a']);
      expect(await store.pendingCount(), 2); // b + c لسه معلّقين
      expect(store.deadCount, 0);
    });

    test('فشل نهائي → dead-letter ويكمّل (ما يسدّش الطابور)', () async {
      final _FakeStore store = _FakeStore();
      await store.enqueue(_op('a'));
      await store.enqueue(_op('b'));
      await store.enqueue(_op('c'));
      final List<String> sent = <String>[];
      final OutboxProcessor p = OutboxProcessor(store, (OutboxOp op) async {
        if (op.id == 'b') throw const TerminalError(); // رفض سيرفر
        sent.add(op.id);
      }, isTransient: _isTransient);

      await p.flush();

      // a + c اتبعتوا، b اتشطبت (dead) — ما سدّتش c.
      expect(sent, <String>['a', 'c']);
      expect(await store.pendingCount(), 0);
      expect(store.deadCount, 1);
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
      }, isTransient: _isTransient);

      await p.flush(); // a يفشل عابر → يقف
      expect(sent, isEmpty);
      expect(await store.pendingCount(), 2);

      await p.flush(); // النت رجع → a ثم b
      expect(sent, <String>['a', 'b']);
      expect(await store.pendingCount(), 0);
    });

    test(
      'عابر بيتكرّر بيتحوّل dead-letter بعد maxAttempts (احتياطي)',
      () async {
        final _FakeStore store = _FakeStore();
        await store.enqueue(_op('x'));
        final OutboxProcessor p = OutboxProcessor(
          store,
          (OutboxOp op) async => throw const SocketLikeError(),
          isTransient: _isTransient,
          maxAttempts: 3,
        );

        await p.flush(); // attempts 0→1، وقف
        expect(await store.pendingCount(), 1);
        await p.flush(); // attempts 1→2، وقف
        expect(await store.pendingCount(), 1);
        await p.flush(); // attempts 2، 2+1>=3 → dead-letter
        expect(await store.pendingCount(), 0);
        expect(store.deadCount, 1);
      },
    );

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
