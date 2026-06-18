import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../enrollment/domain/gender.dart';
import '../domain/child_card.dart';
import '../domain/child_summary.dart';

part 'parent_repository.g.dart';

/// بيانات بوابة ولي الأمر: أولاده + كارت متابعة كل طفل (عبر RLS).
class ParentRepository {
  ParentRepository(this._client);

  final SupabaseClient _client;

  /// أولاد ولي الأمر الحالي (RLS بيفلتر روابطه).
  Future<List<ChildSummary>> fetchMyChildren() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('guardian_link')
        .select('student:student_person_id(id, full_name, gender)');
    return rows.map((Map<String, dynamic> r) {
      final Map<String, dynamic> s = r['student'] as Map<String, dynamic>;
      return ChildSummary(
        studentPersonId: s['id'] as String,
        fullName: s['full_name'] as String,
        gender: Gender.fromDb(s['gender'] as String?),
      );
    }).toList();
  }

  /// كارت طفل: الحلقة النشطة + آخر تسميع + ملخّص الحضور.
  Future<ChildCard> fetchChildCard(String studentPersonId) async {
    final Map<String, dynamic>? enr = await _client
        .from('enrollment')
        .select('id, circle:circle_id(name)')
        .eq('student_person_id', studentPersonId)
        .eq('status', 'active')
        .maybeSingle();
    final String? enrollmentId = enr?['id'] as String?;
    final String? circleName =
        (enr?['circle'] as Map<String, dynamic>?)?['name'] as String?;

    if (enrollmentId == null) {
      return const ChildCard(present: 0, absent: 0, excused: 0, late: 0);
    }

    final List<Map<String, dynamic>> tasmee = await _client
        .from('daily_tasmee')
        .select('score, passed, portion:portion_id(name)')
        .eq('enrollment_id', enrollmentId)
        .order('attempt_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(1);
    LatestTasmee? latest;
    if (tasmee.isNotEmpty) {
      final Map<String, dynamic> t = tasmee.first;
      latest = LatestTasmee(
        score: (t['score'] as num).toInt(),
        passed: t['passed'] as bool,
        portionName:
            ((t['portion'] as Map<String, dynamic>?)?['name'] as String?) ?? '',
      );
    }

    final List<Map<String, dynamic>> att = await _client
        .from('attendance')
        .select('status')
        .eq('enrollment_id', enrollmentId);
    int present = 0, absent = 0, excused = 0, late = 0;
    for (final Map<String, dynamic> a in att) {
      switch (a['status'] as String) {
        case 'present':
          present++;
        case 'absent':
          absent++;
        case 'absent_excused':
          excused++;
        case 'late':
          late++;
      }
    }

    return ChildCard(
      circleName: circleName,
      latestTasmee: latest,
      present: present,
      absent: absent,
      excused: excused,
      late: late,
    );
  }
}

@riverpod
ParentRepository parentRepository(Ref ref) =>
    ParentRepository(ref.watch(supabaseClientProvider));
