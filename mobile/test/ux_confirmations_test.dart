import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quran_center/app/shell/sync_status_sheet.dart';
import 'package:quran_center/core/auth/auth_providers.dart';
import 'package:quran_center/core/auth/auth_repository.dart';
import 'package:quran_center/core/db/local_db.dart';
import 'package:quran_center/core/settings/settings_repository.dart';
import 'package:quran_center/core/supabase/supabase_providers.dart';
import 'package:quran_center/core/sync/outbox_op.dart';
import 'package:quran_center/core/sync/outbox_store.dart';
import 'package:quran_center/features/home/presentation/screens/dashboard_screen.dart';
import 'package:quran_center/features/settings/presentation/screens/settings_screen.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuth implements AuthRepository {
  int signOuts = 0;
  @override
  Session? get currentSession => null;
  @override
  Stream<AuthState> get authStateChanges => const Stream<AuthState>.empty();
  @override
  Future<void> signOut() async {
    signOuts++;
  }

  @override
  Future<void> resetPassword(String email) async {}
  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {}
}

class FakeQueueDb extends LocalDb {
  FakeQueueDb() : super(NativeDatabase.memory());
  bool discarded = false;
  @override
  Future<List<OutboxOp>> pending({int limit = 100}) async => <OutboxOp>[];
  @override
  Future<List<DeadLetterEntry>> deadLetters({int limit = 100}) async =>
      discarded
      ? <DeadLetterEntry>[]
      : <DeadLetterEntry>[
          const DeadLetterEntry(
            id: 'grade',
            type: OutboxOpType.tasmeeRecord,
            attempts: 1,
            displayLabel: 'محمد — تسميع ٨/١٠',
            lastError: '42501',
          ),
        ];
  @override
  Stream<SyncStatus> watchSyncStatus() =>
      Stream<SyncStatus>.value(const SyncStatus(pending: 0, dead: 1));
  @override
  Future<void> discard(String id) async {
    discarded = true;
  }
}

Widget app(Widget home) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  home: home,
);

void main() {
  testWidgets('Logout asks before ending the account session', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PackageInfo.setMockInitialValues(
      appName: 'Quran',
      packageName: 'app.quran',
      version: '1.0',
      buildNumber: '1',
      buildSignature: 'test',
    );
    final auth = FakeAuth();
    final client = (await tester.runAsync(
      () async => SupabaseClient(
        'https://example.invalid',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    ))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          supabaseClientProvider.overrideWithValue(client),
          appSettingsProvider.overrideWith((ref) async => AppSettings.defaults),
          homeNameProvider.overrideWith((ref) async => 'أحمد'),
        ],
        child: app(const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    await tester.scrollUntilVisible(
      find.byIcon(Icons.logout),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('تسجيل خروج؟'), findsOneWidget);
    expect(auth.signOuts, 0);
    await tester.tap(find.text("تسجيل خروج"));
    await tester.pump();
    expect(auth.signOuts, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(client.dispose);
  });
  testWidgets('Discard asks before deleting a locally saved grade', (
    tester,
  ) async {
    final db = (await tester.runAsync(() async => FakeQueueDb()))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localDbProvider.overrideWithValue(db)],
        child: app(const Scaffold(body: SyncStatusSheet())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('محمد — تسميع ٨/١٠'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('حذف الدرجة؟'), findsOneWidget);
    expect(db.discarded, false);
    await tester.tap(find.text("حذف نهائي"));
    await tester.pump();
    await tester.pump();
    expect(db.discarded, true);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(db.close);
  });
}
