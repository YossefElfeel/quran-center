import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/certificate_repository.dart';

part 'child_certificates_controller.g.dart';

/// شهادات الطفل المُصدَرة.
@riverpod
Future<List<CertificateRow>> childCertificates(
  Ref ref,
  String studentPersonId,
) => ref
    .watch(certificateRepositoryProvider)
    .fetchChildCertificates(studentPersonId);
