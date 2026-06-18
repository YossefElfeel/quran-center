import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/competition_models.dart';
import '../domain/competition_scoring.dart';

part 'competition_repository.g.dart';

/// المسابقة: قراءة/إنشاء + المتقدّمون + التحكيم + النتائج المرتّبة.
class CompetitionRepository {
  CompetitionRepository(this._client);

  final SupabaseClient _client;

  Future<List<CompetitionRow>> fetchCompetitions() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('competition')
        .select('id, name, status')
        .order('created_at', ascending: false);
    return rows.map(CompetitionRow.fromMap).toList();
  }

  Future<void> createCompetition(String name) async {
    await _client.from('competition').insert(<String, dynamic>{
      'name': name,
      'status': 'open',
    });
  }

  Future<List<CompetitionApplicationRow>> fetchApplications(
    String competitionId,
  ) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('competition_application')
        .select(
          'id, status, youtube_url, '
          'student:student_person_id(full_name), '
          'pub:public_registration_id(name)',
        )
        .eq('competition_id', competitionId)
        .order('created_at', ascending: true);
    return rows.map(CompetitionApplicationRow.fromMap).toList();
  }

  /// المحكّم يدرّج (upsert — درجة واحدة لكل محكّم لكل متقدّم).
  Future<void> scoreApplication(String applicationId, double score) async {
    await _client.from('competition_score').upsert(<String, dynamic>{
      'application_id': applicationId,
      'score': score,
    }, onConflict: 'application_id,judge_person_id');
  }

  /// نتائج مرتّبة للمتقدّمين المقبولين (تجميع + كسر تعادل في الدومين).
  Future<List<CompetitionResultRow>> fetchResults(String competitionId) async {
    final List<Map<String, dynamic>> apps = await _client
        .from('competition_application')
        .select(
          'id, student:student_person_id(full_name), '
          'pub:public_registration_id(name)',
        )
        .eq('competition_id', competitionId)
        .eq('status', 'accepted');
    if (apps.isEmpty) return <CompetitionResultRow>[];

    final Map<String, String> nameByApp = <String, String>{};
    final List<String> ids = <String>[];
    for (final Map<String, dynamic> a in apps) {
      final String id = a['id'] as String;
      ids.add(id);
      final Map<String, dynamic>? st = a['student'] as Map<String, dynamic>?;
      final Map<String, dynamic>? pb = a['pub'] as Map<String, dynamic>?;
      nameByApp[id] =
          (st?['full_name'] as String?) ?? (pb?['name'] as String?) ?? 'متقدّم';
    }

    final List<Map<String, dynamic>> scoreRows = await _client
        .from('competition_score')
        .select('application_id, score')
        .inFilter('application_id', ids);
    final Map<String, List<double>> byApp = <String, List<double>>{
      for (final String id in ids) id: <double>[],
    };
    for (final Map<String, dynamic> s in scoreRows) {
      final String aid = s['application_id'] as String;
      (byApp[aid] ??= <double>[]).add((s['score'] as num).toDouble());
    }

    return rankApplicants(byApp)
        .map(
          (ApplicantResult r) => CompetitionResultRow(
            applicantName: nameByApp[r.applicationId] ?? 'متقدّم',
            average: r.average,
            judgeCount: r.judgeCount,
          ),
        )
        .toList();
  }
}

@riverpod
CompetitionRepository competitionRepository(Ref ref) =>
    CompetitionRepository(ref.watch(supabaseClientProvider));
