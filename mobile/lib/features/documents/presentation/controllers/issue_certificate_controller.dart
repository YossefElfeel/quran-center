import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/certificate_repository.dart';
import '../../domain/eligible_student.dart';

part 'issue_certificate_controller.g.dart';

/// الطلبة المؤهّلين لشهادة إتمام (zero-debt).
@riverpod
Future<List<EligibleStudent>> eligibleStudents(Ref ref) =>
    ref.watch(certificateRepositoryProvider).fetchEligibleStudents();
