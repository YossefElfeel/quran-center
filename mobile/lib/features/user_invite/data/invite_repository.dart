import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/invite_failure.dart';

part 'invite_repository.g.dart';

/// دعوة مستخدم (ولي أمر/معلّم/مشرف/أدمن) عبر Edge Function `invite-user`
/// (service-role سيرفر-سايد، بيتأكد إن النده أدمن). بيرجّع رابط الدعوة عشان
/// يتبعت للمستخدم (واتساب/إيميل) يكمّل بيه الباسورد. الفشل بيترمي كـ
/// [InviteException] والرسالة بتتعمل في الـ presentation.
class InviteRepository {
  InviteRepository(this._client);

  final SupabaseClient _client;

  Future<String?> inviteUser({
    required String email,
    required String fullName,
    required String role,
    String? existingPersonId,
  }) async {
    try {
      final FunctionResponse res = await _client.functions.invoke(
        'invite-user',
        body: <String, dynamic>{
          'email': email,
          'full_name': fullName,
          'role': role,
          'existing_person_id': ?existingPersonId,
        },
      );
      final dynamic data = res.data;
      if (data is Map && data['action_link'] is String) {
        return data['action_link'] as String;
      }
      throw const InviteException(InviteFailure.linkMissing);
    } on FunctionException catch (e) {
      throw InviteException(InviteFailure.fromResponse(e.status, e.details));
    }
  }
}

@riverpod
InviteRepository inviteRepository(Ref ref) =>
    InviteRepository(ref.watch(supabaseClientProvider));
