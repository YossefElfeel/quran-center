import 'package:supabase_flutter/supabase_flutter.dart';

import '../env/env.dart';
import '../error/app_exception.dart';
import '../network/network_status.dart';

/// واجهة الـ auth — تسهّل الـ mocking في الاختبارات وتعزل Supabase.
abstract class AuthRepository {
  Session? get currentSession;
  Stream<AuthState> get authStateChanges;
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> resetPassword(String email);
}

/// تطبيق فعلي فوق Supabase Auth.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      if (e.code == 'user_banned') {
        throw const PermissionDeniedException(
          'الحساب موقوف — تواصل مع الإدارة',
        );
      }
      if (e.code == 'invalid_credentials') {
        throw const ValidationException('الإيميل أو كلمة السر مش صحيحين');
      }
      if (e.code == 'over_request_rate_limit') {
        throw const ValidationException('محاولات كتير — استنى شوية وجرّب تاني');
      }
      if (isOfflineError(e)) throw const NetworkException();
      throw const ValidationException('تعذّر تسجيل الدخول — جرّب تاني');
    } catch (e) {
      if (isOfflineError(e)) throw const NetworkException();
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email) {
    if (Env.webUrl.isEmpty) {
      throw const ValidationException(
        'رابط الموقع مش مضبوط — تواصل مع الإدارة',
      );
    }
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: '${Env.webUrl}/auth/confirm',
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
