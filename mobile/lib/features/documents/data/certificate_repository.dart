import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/certificate_kind.dart';

part 'certificate_repository.g.dart';

/// صف شهادة مُصدَرة.
class CertificateRow {
  const CertificateRow({required this.kind, required this.issuedAt});

  factory CertificateRow.fromMap(Map<String, dynamic> map) => CertificateRow(
    kind: CertificateKind.fromDb(map['kind'] as String),
    issuedAt: DateTime.parse(map['issued_at'] as String),
  );

  final CertificateKind kind;
  final DateTime issuedAt;
}

/// الشهادات: قراءة شهادات الطفل + إصدار (المشرف/الأدمن — البوابة على RLS + trigger).
class CertificateRepository {
  CertificateRepository(this._client);

  final SupabaseClient _client;

  Future<List<CertificateRow>> fetchChildCertificates(
    String studentPersonId,
  ) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('certificate')
        .select('kind, issued_at')
        .eq('student_person_id', studentPersonId)
        .order('issued_at', ascending: false);
    return rows.map(CertificateRow.fromMap).toList();
  }

  /// إصدار شهادة (الأهلية متفروضة سيرفر-سايد: zero-debt للإتمام).
  Future<void> issueCertificate({
    required String studentPersonId,
    required CertificateKind kind,
  }) async {
    await _client.from('certificate').insert(<String, dynamic>{
      'student_person_id': studentPersonId,
      'kind': kind.dbValue,
    });
  }
}

@riverpod
CertificateRepository certificateRepository(Ref ref) =>
    CertificateRepository(ref.watch(supabaseClientProvider));
