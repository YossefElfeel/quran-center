import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';

part 'invite_repository.g.dart';

/// دعوة مستخدم (ولي أمر/معلّم/مشرف/أدمن) عبر Edge Function `invite-user`
/// (service-role سيرفر-سايد، بيتأكد إن النده أدمن). بيرجّع رابط الدعوة عشان
/// يتبعت للمستخدم (واتساب/إيميل) يكمّل بيه الباسورد.
class InviteRepository {
  InviteRepository(this._client);

  final SupabaseClient _client;

  Future<String?> inviteUser({
    required String email,
    required String fullName,
    required String role,
  }) async {
    try {
      final FunctionResponse res = await _client.functions.invoke(
        'invite-user',
        body: <String, dynamic>{
          'email': email,
          'full_name': fullName,
          'role': role,
        },
      );
      final dynamic data = res.data;
      if (data is Map && data['action_link'] is String) {
        return data['action_link'] as String;
      }
      return null;
    } on FunctionException catch (e) {
      if (e.status == 403) {
        throw const PermissionDeniedException('الدعوة للأدمن بس');
      }
      throw const ValidationException(
        'مش قادرين نبعت الدعوة — اتأكد من البيانات وجرّب تاني',
      );
    }
  }
}

@riverpod
InviteRepository inviteRepository(Ref ref) =>
    InviteRepository(ref.watch(supabaseClientProvider));
