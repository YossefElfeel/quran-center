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
    if (e != null) {
      e.attempts++;
      e.lastError = error;
    }
  }

  @override
  Future<void> markDeadLetter(String id, String error) async {
    final _Entry? e = _m[id];
    if (e != null) {
      e.attempts++;
      e.status = 'dead';
      e.lastError = error;
    }
  }

  @override
  Future<int> pendingCount() async =>
      _m.values.where((_Entry e) => e.status == 'pending').length;

  @override
  Future<int> deadLetterCount() async =>
      _m.values.where((_Entry e) => e.status == 'dead').length;

  @override
  Future<List<DeadLetterEntry>> deadLetters({int limit = 100}) async {
    final List<_Entry> es =
        _m.values.where((_Entry e) => e.status == 'dead').toList()
          ..sort((_Entry a, _Entry b) => a.seq.compareTo(b.seq));
    return es
        .take(limit)
        .map(
          (_Entry e) => DeadLetterEntry(
            id: e.op.id,
            type: e.op.type,
            attempts: e.attempts,
            lastError: e.lastError,
            sessionId: e.op.payload['session_id'] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<void> requeue(String id) async {
    final _Entry? e = _m[id];
    if (e != null) {
      e.status = 'pending';
      e.attempts = 0;
      e.lastError = null;
    }
  }

  @override
  Future<void> discard(String id) async => _m.remove(id);

  int get deadCount => _m.values.where((_Entry e) => e.status == 'dead').length;
}

class _Entry {
  _Entry(this.op, this.seq);
  final OutboxOp op;
  final int seq;
  String status = 'pending';
  int attempts = 0;
  String? lastError;
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
  test(
    'One flush drains multiple pages and concurrent callers wait for the same drain',
    () async {
      final _FakeStore store = _FakeStore();
      for (int i = 0; i < 235; i++) {
        await store.enqueue(_op('op-$i'));
      }
      final List<String> sent = <String>[];
      final OutboxProcessor processor = OutboxProcessor(store, (op) async {
        await Future<void>.delayed(Duration.zero);
        sent.add(op.id);
      }, isTransient: _isTransient);
      await Future.wait<void>(<Future<void>>[
        processor.flush(),
        processor.flush(),
        processor.flush(),
      ]);
      expect(sent.length, 235);
      expect(sent.toSet().length, 235);
      expect(await store.pendingCount(), 0);
    },
  );
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
    test(
      'Rejected grade blocks its close across retries, while another session syncs',
      () async {
        final store = _FakeStore();
        for (final op in <OutboxOp>[
          const OutboxOp(
            id: 'grade',
            type: OutboxOpType.tasmeeRecord,
            payload: {'session_id': 's1'},
          ),
          const OutboxOp(
            id: 'close',
            type: OutboxOpType.sessionClose,
            payload: {'session_id': 's1'},
          ),
          const OutboxOp(
            id: 'other',
            type: OutboxOpType.sessionClose,
            payload: {'session_id': 's2'},
          ),
        ]) {
          await store.enqueue(op);
        }
        bool reject = true;
        final sent = <String>[];
        final processor = OutboxProcessor(store, (op) async {
          if (op.id == 'grade' && reject) throw const TerminalError();
          sent.add(op.id);
        }, isTransient: _isTransient);
        await processor.flush();
        expect(sent, ['other']);
        expect(store.deadCount, 2);
        await store.requeue('close');
        await processor.flush();
        expect(sent, ['other']);
        reject = false;
        await store.requeue('grade');
        await store.requeue('close');
        await processor.flush();
        expect(sent, ['other', 'grade', 'close']);
        expect(store.deadCount, 0);
      },
    );

    test(
      'Rejected offline session open prevents dependent attendance from being sent',
      () async {
        final store = _FakeStore();
        await store.enqueue(
          const OutboxOp(
            id: 'open',
            type: OutboxOpType.sessionOpen,
            payload: {'session_id': 's1'},
          ),
        );
        await store.enqueue(
          const OutboxOp(
            id: 'attendance',
            type: OutboxOpType.attendanceMark,
            payload: {'session_id': 's1'},
          ),
        );
        final sent = <String>[];
        final processor = OutboxProcessor(store, (op) async {
          sent.add(op.id);
          if (op.id == 'open') throw const TerminalError();
        }, isTransient: _isTransient);
        await processor.flush();
        expect(sent, ['open']);
        expect(store.deadCount, 2);
      },
    );
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

    test('انقطاع طويل يحافظ على الدرجة حتى بعد محاولات كتير', () async {
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
      await p.flush(); // محاولة أخرى: الدرجة تفضل محفوظة ومعلّقة
      expect(await store.pendingCount(), 1);
      expect(store.deadCount, 0);
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

  group('إدارة العمليات الميتة (dead-letter)', () {
    test('deadLetters تعرض الميتة مع آخر خطأ', () async {
      final _FakeStore store = _FakeStore();
      await store.enqueue(_op('a'));
      await store.enqueue(_op('b'));
      final OutboxProcessor p = OutboxProcessor(store, (OutboxOp op) async {
        throw const TerminalError();
      }, isTransient: _isTransient);

      await p.flush();

      final List<DeadLetterEntry> dead = await store.deadLetters();
      expect(dead.length, 2);
      expect(dead.first.id, 'a'); // ترتيب FIFO
      expect(dead.first.lastError, isNotNull);
      expect(await store.deadLetterCount(), 2);
    });

    test('requeue يرجّع العملية للطابور وflush يعيد إرسالها', () async {
      final _FakeStore store = _FakeStore();
      await store.enqueue(_op('a'));
      bool reject = true;
      final List<String> sent = <String>[];
      final OutboxProcessor p = OutboxProcessor(store, (OutboxOp op) async {
        if (reject) throw const TerminalError();
        sent.add(op.id);
      }, isTransient: _isTransient);

      await p.flush(); // a → dead
      expect(await store.deadLetterCount(), 1);

      reject = false; // اتصلح سبب الرفض
      await store.requeue('a');
      expect(await store.pendingCount(), 1);
      expect(await store.deadLetterCount(), 0);

      await p.flush();
      expect(sent, <String>['a']);
      expect(await store.pendingCount(), 0);
    });

    test('discard يشيل العملية الميتة نهائيًا', () async {
      final _FakeStore store = _FakeStore();
      await store.enqueue(_op('a'));
      final OutboxProcessor p = OutboxProcessor(
        store,
        (OutboxOp op) async => throw const TerminalError(),
        isTransient: _isTransient,
      );

      await p.flush();
      expect(await store.deadLetterCount(), 1);

      await store.discard('a');
      expect(await store.deadLetterCount(), 0);
      expect(await store.deadLetters(), isEmpty);
    });
  });
}
