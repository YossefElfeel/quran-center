import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/guardian_link_row.dart';
import '../domain/household_option.dart';
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
        .order('enrolled_at', ascending: true)
        .timeout(const Duration(seconds: 12));
    final Map<String, StudentOption> byId = <String, StudentOption>{};
    for (final Map<String, dynamic> r in rows) {
      final Map<String, dynamic>? s = r['student'] as Map<String, dynamic>?;
      final String? id = s?['id'] as String?;
      if (id == null) continue;
      byId[id] = StudentOption(
        personId: id,
        fullName: (s?['full_name'] as String?) ?? '—',
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
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 12));
    return rows.map(GuardianLinkRow.fromMap).toList();
  }

  /// الأسر المتاحة (لاختيار أسرة ولي الأمر أو إنشاء واحدة جديدة).
  Future<List<HouseholdOption>> fetchHouseholds() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('household')
        .select('id, name')
        .order('name', ascending: true)
        .timeout(const Duration(seconds: 12));
    return rows
        .map(
          (Map<String, dynamic> r) =>
              HouseholdOption(id: r['id'] as String, name: r['name'] as String),
        )
        .toList();
  }

  /// ينشئ ولي أمر (شخص بالغ + دور parent) ويربطه بطفل **ويضمّه لأسرة** في
  /// معاملة ذرّية عبر الدالة `create_guardian_with_household` — عشان ميتقفلش
  /// بره بوابة الاشتراك (اللي بتتطلّب عضوية أسرة). لو [householdId] فاضي
  /// بتتعمل أسرة جديدة باسم [newHouseholdName] (أو اسم ولي الأمر).
  Future<void> createGuardianWithHousehold({
    required String guardianName,
    required String childPersonId,
    required String relation,
    String? householdId,
    String? newHouseholdName,
  }) async {
    await _client.rpc<dynamic>(
      'create_guardian_with_household',
      params: <String, dynamic>{
        'p_guardian_name': guardianName,
        'p_child_person_id': childPersonId,
        'p_relation': relation,
        'p_household_id': householdId,
        'p_new_household_name': newHouseholdName,
      },
    );
  }
}

@riverpod
FamilyRepository familyRepository(Ref ref) =>
    FamilyRepository(ref.watch(supabaseClientProvider));
