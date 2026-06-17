import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../enrollment/domain/gender.dart';
import '../domain/circle_option.dart';
import '../domain/level_option.dart';
import '../domain/waiting_applicant.dart';

part 'intake_repository.g.dart';

/// التحاق الطلبة: قائمة الانتظار + اختبار تحديد المستوى + الإسناد لحلقة.
class IntakeRepository {
  IntakeRepository(this._client);

  final SupabaseClient _client;

  Future<List<WaitingApplicant>> fetchWaiting() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('waiting_list')
        .select(
          'id, level_id, status, level:level_id(name), '
          'student:student_person_id(id, full_name, gender)',
        )
        .eq('status', 'waiting')
        .order('created_at', ascending: true);
    return rows.map(WaitingApplicant.fromMap).toList();
  }

  Future<List<LevelOption>> fetchLevelOptions() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('level')
        .select('id, name, curriculum:curriculum_id(name)')
        .order('ord', ascending: true);
    return rows.map((Map<String, dynamic> r) {
      final Map<String, dynamic>? cur = r['curriculum'] as Map<String, dynamic>?;
      final String curName = cur?['name'] as String? ?? '';
      final String name = r['name'] as String;
      return LevelOption(
        id: r['id'] as String,
        label: curName.isEmpty ? name : '$curName — $name',
      );
    }).toList();
  }

  Future<List<CircleOption>> fetchCirclesOfLevel(String levelId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('circle')
        .select('id, name')
        .eq('level_id', levelId)
        .order('created_at', ascending: true);
    return rows
        .map((Map<String, dynamic> r) =>
            CircleOption(id: r['id'] as String, name: r['name'] as String))
        .toList();
  }

  Future<void> addApplicant({
    required String name,
    required Gender gender,
    required String levelId,
  }) async {
    final Map<String, dynamic> person = await _client
        .from('person')
        .insert(<String, dynamic>{
          'full_name': name,
          'gender': gender.dbValue,
          'is_minor': true,
        })
        .select('id')
        .single();
    await _client.from('waiting_list').insert(<String, dynamic>{
      'student_person_id': person['id'] as String,
      'level_id': levelId,
      'status': 'waiting',
    });
  }

  /// المشرف بيسجّل نتيجة اختبار تحديد المستوى ويحدّث المستوى المستهدف للمتقدّم.
  Future<void> recordPlacement({
    required String waitingId,
    required String studentPersonId,
    String? supervisorId,
    required String resultLevelId,
    String? notes,
  }) async {
    await _client.from('placement_test').insert(<String, dynamic>{
      'student_person_id': studentPersonId,
      'supervisor_id': ?supervisorId,
      'result_level_id': resultLevelId,
      'notes': ?notes,
    });
    await _client
        .from('waiting_list')
        .update(<String, dynamic>{'level_id': resultLevelId})
        .eq('id', waitingId);
  }

  /// إسناد المتقدّم لحلقة: enrollment نشط + تعليم قائمة الانتظار accepted.
  Future<void> enroll({
    required String waitingId,
    required String studentPersonId,
    required String circleId,
  }) async {
    await _client.from('enrollment').insert(<String, dynamic>{
      'student_person_id': studentPersonId,
      'circle_id': circleId,
      'status': 'active',
    });
    await _client
        .from('waiting_list')
        .update(<String, dynamic>{'status': 'accepted'})
        .eq('id', waitingId);
  }
}

@riverpod
IntakeRepository intakeRepository(Ref ref) =>
    IntakeRepository(ref.watch(supabaseClientProvider));
