import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_providers.dart';
import 'auth_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    SupabaseAuthRepository(ref.watch(supabaseClientProvider));

/// بثّ تغيّر حالة الدخول (يستخدمه الراوتر لإعادة التقييم).
@riverpod
Stream<AuthState> authState(Ref ref) =>
    ref.watch(authRepositoryProvider).authStateChanges;

/// أدوار المستخدم الحالي **هو بس** (بنفلتر صراحةً على person_id بتاعه — مش بنعتمد
/// على اتساع الـ RLS، لأن الأدمن يقدر يقرا أدوار الكل).
@riverpod
Future<List<String>> currentRoles(Ref ref) async {
  ref.watch(authStateProvider); // أعِد القراءة عند تغيّر الجلسة
  final SupabaseClient client = ref.watch(supabaseClientProvider);
  final String? userId = client.auth.currentUser?.id;
  if (userId == null) return const <String>[];

  final Map<String, dynamic>? me = await client
      .from('app_user')
      .select('person_id')
      .eq('auth_user_id', userId)
      .maybeSingle();
  if (me == null) return const <String>[];

  final List<Map<String, dynamic>> rows = await client
      .from('role_assignment')
      .select('role')
      .eq('person_id', me['person_id'] as String);
  return rows.map((Map<String, dynamic> r) => r['role'] as String).toList();
}
