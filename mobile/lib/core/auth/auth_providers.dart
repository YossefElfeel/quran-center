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

/// معرّف الـ person للمستخدم الحالي (للاستخدام في supervisor_id وغيره).
@riverpod
Future<String?> currentPersonId(Ref ref) async {
  ref.watch(authStateProvider);
  final SupabaseClient client = ref.watch(supabaseClientProvider);
  final String? userId = client.auth.currentUser?.id;
  if (userId == null) return null;
  final Map<String, dynamic>? me = await client
      .from('app_user')
      .select('person_id')
      .eq('auth_user_id', userId)
      .maybeSingle()
      .timeout(const Duration(seconds: 12));
  return me?['person_id'] as String?;
}

/// أدوار المستخدم الحالي **هو بس** (بنفلتر صراحةً على person_id بتاعه — مش بنعتمد
/// على اتساع الـ RLS، لأن الأدمن يقدر يقرا أدوار الكل).
@riverpod
Future<List<String>> currentRoles(Ref ref) async {
  final String? personId = await ref.watch(currentPersonIdProvider.future);
  if (personId == null) return const <String>[];

  final SupabaseClient client = ref.watch(supabaseClientProvider);
  final List<Map<String, dynamic>> rows = await client
      .from('role_assignment')
      .select('role')
      .eq('person_id', personId)
      .timeout(const Duration(seconds: 12));
  return rows.map((Map<String, dynamic> r) => r['role'] as String).toList();
}
