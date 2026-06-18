import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/household_member_row.dart';
import '../controllers/household_members_controller.dart';
import '../widgets/add_household_member_sheet.dart';

/// أفراد أسرة (أولياء أمور + طلبة) — للأدمن.
class HouseholdMembersScreen extends ConsumerWidget {
  const HouseholdMembersScreen({
    required this.householdId,
    required this.householdName,
    super.key,
  });

  final String householdId;
  final String householdName;

  void _add(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) =>
          AddHouseholdMemberSheet(householdId: householdId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<HouseholdMemberRow>> state = ref.watch(
      householdMembersControllerProvider(householdId),
    );
    return AppScaffold(
      title: householdName,
      actions: <Widget>[
        IconButton(
          tooltip: l.subsAddMember,
          icon: const Icon(Icons.person_add),
          onPressed: () => _add(context),
        ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.subsMembersLoadError,
          onRetry: () =>
              ref.invalidate(householdMembersControllerProvider(householdId)),
        ),
        data: (List<HouseholdMemberRow> items) => items.isEmpty
            ? EmptyState(message: l.subsNoMembers, icon: Icons.group_add)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final HouseholdMemberRow m = items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.md,
                    ),
                    child: ListTile(
                      leading: Icon(
                        m.role == 'guardian' ? Icons.person : Icons.child_care,
                        color: AppColors.primary,
                      ),
                      title: Text(m.personName),
                      subtitle: Text(m.roleAr),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
