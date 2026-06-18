import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/parent_repository.dart';
import '../../domain/journey_stop.dart';
import '../../domain/monthly_plan_view.dart';

part 'child_extras_controller.g.dart';

/// خطة الشهر الحالي لحلقة الطفل.
@riverpod
Future<MonthlyPlanView?> childMonthlyPlan(Ref ref, String studentPersonId) =>
    ref.watch(parentRepositoryProvider).fetchChildMonthlyPlan(studentPersonId);

/// رحلة الطفل عبر الحلقات (حق المحفّظ).
@riverpod
Future<List<JourneyStop>> childJourney(Ref ref, String studentPersonId) =>
    ref.watch(parentRepositoryProvider).fetchChildJourney(studentPersonId);
