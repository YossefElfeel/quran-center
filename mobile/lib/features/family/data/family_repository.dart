import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/guardian_link_row.dart';
import '../domain/student_option.dart';

part 'family_repository.g.dart';

/// إدارة الأسرة (أدمن): ربط أولياء الأمور بالأطفال.
class FamilyRepository {
  FamilyRepository(this._client);

  final SupabaseClient _client;

  /// الطلبة المسجّلين (لاختيار الطفل).
  Future<List<StudentOption>> fetchStudents() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('enrollment')
        .select('student:student_person_id(id, full_name)')
        .eq('status', 'active')
        .order('enrolled_at', ascending: true);
    final Map<String, StudentOption> byId = <String, StudentOption>{};
    for (final Map<String, dynamic> r in rows) {
      final Map<String, dynamic> s = r['student'] as Map<String, dynamic>;
      final String id = s['id'] as String;
      byId[id] = StudentOption(
        personId: id,
        fullName: s['full_name'] as String,
      );
    }
    return byId.values.toList();
  }

  Future<List<GuardianLinkRow>> fetchLinks() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('guardian_link')
        .select(
          'relation, guardian:guardian_person_id(full_name), '
          'student:student_person_id(full_name)',
        )
        .order('created_at', ascending: false);
    return rows.map(GuardianLinkRow.fromMap).toList();
  }

  /// ينشئ ولي أمر جديد (شخص + دور parent) ويربطه بطفل.
  Future<void> createGuardianAndLink({
    required String guardianName,
    required String childPersonId,
    required String relation,
  }) async {
    final Map<String, dynamic> guardian = await _client
        .from('person')
        .insert(<String, dynamic>{'full_name': guardianName})
        .select('id')
        .single();
    final String guardianId = guardian['id'] as String;
    await _client.from('role_assignment').insert(<String, dynamic>{
      'person_id': guardianId,
      'role': 'parent',
    });
    await _client.from('guardian_link').insert(<String, dynamic>{
      'guardian_person_id': guardianId,
      'student_person_id': childPersonId,
      'relation': relation,
    });
  }
}

@riverpod
FamilyRepository familyRepository(Ref ref) =>
    FamilyRepository(ref.watch(supabaseClientProvider));
