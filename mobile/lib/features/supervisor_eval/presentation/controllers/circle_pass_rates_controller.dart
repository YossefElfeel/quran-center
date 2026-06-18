import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/supervisor_eval_repository.dart';
import '../../domain/circle_pass_rate.dart';

part 'circle_pass_rates_controller.g.dart';

/// نِسَب نجاح الحلقات (مرتّبة الأقل أولًا) — للوحة محتاج انتباه.
@riverpod
Future<List<CirclePassRate>> circlePassRates(Ref ref) =>
    ref.watch(supervisorEvalRepositoryProvider).fetchCirclePassRates();
