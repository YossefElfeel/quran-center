import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/household_summary.dart';
import '../controllers/households_controller.dart';
import '../widgets/household_tile.dart';

/// الأدمن — اشتراكات الأسر: عرض الحالة + إضافة أسرة + تسجيل دفعة كاش.
class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  Future<void> _addHousehold(BuildContext context, WidgetRef ref) async {
    final AppL10n l = AppL10n.of(context);
    final TextEditingController name = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.subsNewHousehold),
        content: AppTextField(
          controller: name,
          autofocus: true,
          label: l.subsHouseholdNameLabel,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.add),
          ),
        ],
      ),
    );
    final String trimmed = name.text.trim();
    name.dispose();
    if (ok == true && trimmed.isNotEmpty) {
      await ref
          .read(householdsControllerProvider.notifier)
          .createHousehold(trimmed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<HouseholdSummary>> state = ref.watch(
      householdsControllerProvider,
    );
    return AppScaffold(
      title: l.navSubscriptions,
      actions: <Widget>[
        IconButton(
          tooltip: l.subsNewHousehold,
          icon: const Icon(Icons.add),
          onPressed: () => _addHousehold(context, ref),
        ),
      ],
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.subsLoadError,
          onRetry: () => ref.invalidate(householdsControllerProvider),
        ),
        data: (List<HouseholdSummary> items) => items.isEmpty
            ? EmptyState(
                message: l.subsNoHouseholds,
                icon: Icons.family_restroom,
              )
            : AppRefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(householdsControllerProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) => HouseholdTile(
                    key: ValueKey<String>(items[i].id),
                    household: items[i],
                    onRecordPayment: () => ref
                        .read(householdsControllerProvider.notifier)
                        .recordPayment(items[i]),
                    onTap: () => context.push(
                      Routes.householdMembers(items[i].id, items[i].name),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
