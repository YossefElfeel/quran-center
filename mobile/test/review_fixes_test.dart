import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_center/app/router/parent_gate.dart';
import 'package:quran_center/core/db/local_db.dart';
import 'package:quran_center/core/sync/outbox_op.dart';
import 'package:quran_center/core/sync/outbox_processor.dart';
import 'package:quran_center/features/family/data/family_repository.dart';
import 'package:quran_center/features/family/domain/guardian_link_row.dart';
import 'package:quran_center/features/family/domain/household_naming.dart';
import 'package:quran_center/features/family/presentation/controllers/guardian_links_controller.dart';
import 'package:quran_center/features/notifications/domain/app_notification.dart';
import 'package:quran_center/features/notifications/notification_router.dart';
import 'package:quran_center/features/session/data/session_cache.dart';
import 'package:quran_center/features/session/data/session_sync.dart';
import 'package:quran_center/features/session/domain/roster_entry.dart';
import 'package:quran_center/features/session/domain/session_write_block.dart';
import 'package:quran_center/features/subscription/domain/payment_amount.dart';
import 'package:quran_center/features/user_invite/domain/invite_failure.dart';
import 'package:quran_center/features/user_invite/presentation/user_invite_labels.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

class _MockFamilyRepository extends Mock implements FamilyRepository {}

OutboxOp _op(String id, String circleId) => OutboxOp(
  id: id,
  type: OutboxOpType.attendanceMark,
  payload: <String, dynamic>{
    'session_id': 's1',
    'enrollment_id': 'e1',
    'status': 'present',
    'circle_id': circleId,
  },
);

AppNotification _n(String type, {String? circleId, String? month}) =>
    AppNotification(
      id: 'n',
      type: type,
      title: 'x',
      circleId: circleId,
      month: month,
      createdAt: DateTime(2026),
    );

void main() {
  group('H2 — dead outbox rows never pin the cached session', () {
    late LocalDb db;
    setUp(() => db = LocalDb(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('pending row keeps cache mode, dead row does not', () async {
      await db.enqueue(_op('a', 'c1'));
      expect(await db.hasUnsyncedSession('c1'), isTrue);
      expect(await db.hasUnsyncedSession('other'), isFalse);

      await db.markDeadLetter('a', 'rejected');
      expect(await db.hasUnsyncedSession('c1'), isFalse);
      expect(await db.deadLetterCount(), 1);
    });

    test('a cache from an earlier day is not "today"', () {
      final String json = encodeTodaySession(
        const TodaySession(sessionId: 's', roster: <RosterEntry>[]),
      );
      expect(isSessionCachedToday(json), isTrue);
      expect(
        isSessionCachedToday(
          json,
          now: DateTime.now().add(const Duration(days: 1)),
        ),
        isFalse,
      );
    });
  });

  group('M3 — freeze/maintenance during sync', () {
    test(
      'permission denial is explained only when the server says so',
      () async {
        const Object denied = 'PostgrestException(code: 42501)';
        expect(
          await explainSessionWriteError(
            denied,
            () async => SessionWriteBlock.freezeSessions,
          ),
          isA<SessionWritesBlockedException>().having(
            (SessionWritesBlockedException e) => e.reason,
            'reason',
            SessionWriteBlock.freezeSessions,
          ),
        );
        // RPC missing/failed → original error.
        expect(
          await explainSessionWriteError(denied, () async => null),
          denied,
        );
        // Not a permission error → no lookup.
        expect(
          await explainSessionWriteError(
            'boom',
            () async => throw StateError('should not be called'),
          ),
          'boom',
        );
        expect(
          SessionWriteBlock.fromDb('maintenance_mode'),
          SessionWriteBlock.maintenanceMode,
        );
        expect(SessionWriteBlock.fromDb(null), isNull);
        expect(SessionWriteBlock.fromDb('weird'), isNull);
      },
    );

    test('a blocked write stays pending instead of dead-lettering', () async {
      final LocalDb db = LocalDb(NativeDatabase.memory());
      addTearDown(db.close);
      await db.enqueue(_op('a', 'c1'));
      final OutboxProcessor processor = OutboxProcessor(
        db,
        (OutboxOp _) async => throw const SessionWritesBlockedException(
          SessionWriteBlock.freezeSessions,
        ),
        isTransient: isTransientSyncError,
      );
      await processor.flush();
      expect(await db.pendingCount(), 1);
      expect(await db.deadLetterCount(), 0);
      expect(isTransientSyncError(StateError('rejected')), isFalse);
    });
  });

  group('M2 — add guardian retry', () {
    test('created id is returned even when the list reload fails', () async {
      final _MockFamilyRepository repo = _MockFamilyRepository();
      int creates = 0;
      when(() => repo.fetchLinks()).thenAnswer(
        (_) async => creates == 0
            ? const <GuardianLinkRow>[]
            : throw StateError('reload failed'),
      );
      when(
        () => repo.createGuardianWithHousehold(
          guardianName: any(named: 'guardianName'),
          childPersonId: any(named: 'childPersonId'),
          relation: any(named: 'relation'),
          householdId: any(named: 'householdId'),
          newHouseholdName: any(named: 'newHouseholdName'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async {
        creates++;
        return 'guardian-1';
      });
      final ProviderContainer container = ProviderContainer(
        overrides: [familyRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final ProviderSubscription<AsyncValue<List<GuardianLinkRow>>> sub =
          container.listen(guardianLinksControllerProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(guardianLinksControllerProvider.future);

      final String id = await container
          .read(guardianLinksControllerProvider.notifier)
          .createLink(
            guardianName: 'محمد أحمد الشريف',
            childPersonId: 'child-1',
            relation: 'father',
          );
      expect(id, 'guardian-1');
      expect(creates, 1);
      // The failed reload surfaces on the list, not as a create failure.
      await expectLater(
        container.read(guardianLinksControllerProvider.future),
        throwsStateError,
      );
    });

    test('household name is suggested from the family (last) name', () {
      expect(suggestedFamilyName('محمد أحمد الشريف'), 'الشريف');
      expect(suggestedFamilyName('  أحمد   محمود  '), 'محمود');
      expect(suggestedFamilyName('محمد أحمد عبد الله'), 'عبد الله');
      expect(suggestedFamilyName('محمد'), '');
    });
  });

  test('M6 — invite failures map to distinct messages', () {
    expect(
      InviteFailure.fromResponse(409, 'Person already has a login'),
      InviteFailure.alreadyHasLogin,
    );
    expect(
      InviteFailure.fromResponse(
        400,
        'Parent needs a household and child link',
      ),
      InviteFailure.parentNeedsHousehold,
    );
    expect(
      InviteFailure.fromResponse(
        422,
        'A user with this email address has already been registered',
      ),
      InviteFailure.emailAlreadyRegistered,
    );
    expect(
      InviteFailure.fromResponse(403, 'Forbidden'),
      InviteFailure.forbidden,
    );
    expect(
      InviteFailure.fromResponse(500, 'invite link failed'),
      InviteFailure.linkFailed,
    );
    expect(InviteFailure.fromResponse(502, null), InviteFailure.unknown);
    final AppL10n l = lookupAppL10n(const Locale('ar'));
    final Set<String> messages = <String>{
      for (final InviteFailure f in InviteFailure.values) f.message(l),
    };
    expect(messages.length, InviteFailure.values.length);
  });

  test('M8 — payment amount must be positive with at most two decimals', () {
    expect(parsePaymentAmount('0'), isNull);
    expect(parsePaymentAmount('٠'), isNull);
    expect(parsePaymentAmount('-5'), isNull);
    expect(parsePaymentAmount('abc'), isNull);
    expect(parsePaymentAmount('10.005'), isNull);
    expect(parsePaymentAmount('١٥٠'), 150);
    expect(parsePaymentAmount('12.5'), 12.5);
  });

  group('L1 — parent child-card gate', () {
    Future<List<String>> parent() async => <String>['parent'];
    test('offline / unknown errors let the parent through', () async {
      expect(
        await parentChildGateRedirect(
          roles: parent,
          subscriptionActive: () async => throw StateError('offline'),
        ),
        isNull,
      );
      expect(
        await parentChildGateRedirect(
          roles: () async => throw StateError('offline'),
          subscriptionActive: () async => false,
        ),
        isNull,
      );
    });
    test('only a definitive inactive answer redirects', () async {
      expect(
        await parentChildGateRedirect(
          roles: parent,
          subscriptionActive: () async => false,
        ),
        parentSubscriptionRoute,
      );
      expect(
        await parentChildGateRedirect(
          roles: parent,
          subscriptionActive: () async => true,
        ),
        isNull,
      );
      expect(
        await parentChildGateRedirect(
          roles: () async => <String>['parent', 'teacher'],
          subscriptionActive: () async => false,
        ),
        isNull,
      );
    });
  });

  group('L4 — notification routing per role', () {
    test('subscription_overdue', () {
      final AppNotification n = _n('subscription_overdue');
      expect(notificationRoute(n, <String>['admin']), '/admin/subscriptions');
      expect(
        notificationRoute(n, <String>['super_admin']),
        '/admin/subscriptions',
      );
      expect(notificationRoute(n, <String>['parent']), '/parent/subscription');
      expect(notificationRoute(n, <String>['supervisor']), isNull);
      expect(
        notificationRoute(n, <String>['supervisor', 'parent']),
        '/parent/subscription',
      );
    });
    test('monthly_eval_missed', () {
      final AppNotification staffCopy = _n(
        'monthly_eval_missed',
        month: '2026-08-01',
      );
      final AppNotification teacherCopy = _n(
        'monthly_eval_missed',
        circleId: 'c1',
        month: '2026-08-01',
      );
      // Teacher + supervisor: the staff copy goes to the approval queue.
      expect(
        notificationRoute(staffCopy, <String>['teacher', 'supervisor']),
        '/supervisor/monthly-eval',
      );
      // Their own circle's copy opens that circle's evaluation.
      expect(
        notificationRoute(teacherCopy, <String>['teacher', 'supervisor']),
        allOf(contains('/teacher/circle/c1/monthly-eval'), contains('month=')),
      );
      expect(
        notificationRoute(staffCopy, <String>['teacher']),
        '/teacher/circles',
      );
      expect(
        notificationRoute(staffCopy, <String>['admin']),
        '/supervisor/monthly-eval',
      );
      expect(notificationRoute(staffCopy, <String>['parent']), isNull);
    });
  });

  test('L11 — unknown or missing relation falls back to other', () {
    GuardianLinkRow row(Object? relation) => GuardianLinkRow.fromMap(
      <String, dynamic>{'relation': relation, 'guardian_name': 'g'},
    );
    expect(row(null).relation, 'other');
    expect(row('uncle').relation, 'other');
    expect(row('Mother').relation, 'mother');
    expect(row('father').relation, 'father');
  });
}
