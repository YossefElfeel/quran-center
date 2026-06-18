import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/enrolled_student.dart';
import '../controllers/circle_roster_controller.dart';
import '../widgets/add_student_sheet.dart';
import '../widgets/student_tile.dart';

/// روستر حلقة — الطلبة المسجّلين + تسجيل طالب جديد.
class CircleRosterScreen extends ConsumerWidget {
  const CircleRosterScreen({
    required this.circleId,
    required this.circleName,
    super.key,
  });

  final String circleId;
  final String circleName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<EnrolledStudent>> state = ref.watch(
      circleRosterControllerProvider(circleId),
    );
    return AppScaffold(
      title: circleName,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext _) => AddStudentSheet(circleId: circleId),
        ),
        icon: const Icon(Icons.person_add),
        label: Text(l.enrEnrollStudent),
      ),
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.enrRosterLoadError,
          onRetry: () =>
              ref.invalidate(circleRosterControllerProvider(circleId)),
        ),
        data: (List<EnrolledStudent> items) => items.isEmpty
            ? EmptyState(message: l.enrRosterEmpty, icon: Icons.groups_outlined)
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) =>
                    StudentTile(student: items[i]),
              ),
      ),
    );
  }
}
