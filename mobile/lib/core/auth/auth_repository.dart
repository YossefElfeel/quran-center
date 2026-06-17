import 'package:supabase_flutter/supabase_flutter.dart';

/// واجهة الـ auth — تسهّل الـ mocking في الاختبارات وتعزل Supabase.
abstract class AuthRepository {
  Session? get currentSession;
  Stream<AuthState> get authStateChanges;
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<void> signOut();
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
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
