import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/waiting_applicant.dart';
import '../controllers/waiting_list_controller.dart';
import '../widgets/add_applicant_sheet.dart';
import '../widgets/applicant_tile.dart';
import '../widgets/enroll_sheet.dart';
import '../widgets/placement_sheet.dart';

/// قائمة الانتظار (الأدمن/المشرف) — متقدّمون + اختبار مستوى + إسناد لحلقة.
class WaitingListScreen extends ConsumerWidget {
  const WaitingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WaitingApplicant>> state = ref.watch(
      waitingListControllerProvider,
    );
    return AppScaffold(
      title: 'قائمة الانتظار',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext _) => const AddApplicantSheet(),
        ),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('متقدّم جديد'),
      ),
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل القائمة',
          onRetry: () => ref.invalidate(waitingListControllerProvider),
        ),
        data: (List<WaitingApplicant> items) => items.isEmpty
            ? const EmptyState(
                message: 'مفيش متقدّمين في الانتظار',
                icon: Icons.inbox_outlined,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final WaitingApplicant a = items[i];
                  return ApplicantTile(
                    applicant: a,
                    onPlacement: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext _) => PlacementSheet(
                        waitingId: a.waitingId,
                        studentPersonId: a.personId,
                      ),
                    ),
                    onEnroll: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext _) => EnrollSheet(
                        waitingId: a.waitingId,
                        studentPersonId: a.personId,
                        levelId: a.levelId,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
