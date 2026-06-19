import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/app/app.dart';
import 'package:quran_center/core/auth/auth_providers.dart';
import 'package:quran_center/core/auth/auth_repository.dart';
import 'package:quran_center/features/home/presentation/screens/dashboard_screen.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Session? get currentSession => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream<AuthState>.empty();

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('من غير جلسة → التطبيق يروح لشاشة الدخول (إيميل)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const QuranCenterApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الإيميل'), findsOneWidget);
  });

  testWidgets('الداشبورد بيعرض دور المستخدم (أدمن)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          currentPersonIdProvider.overrideWith((ref) async => 'person-1'),
          currentRolesProvider.overrideWith((ref) async => <String>['admin']),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('أدمن'), findsOneWidget);
  });
}
