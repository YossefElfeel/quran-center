import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/household_summary.dart';
import '../controllers/households_controller.dart';
import '../widgets/household_tile.dart';

/// الأدمن — اشتراكات الأسر: عرض الحالة + إضافة أسرة + تسجيل دفعة كاش.
class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  Future<void> _addHousehold(BuildContext context, WidgetRef ref) async {
    final TextEditingController name = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('أسرة جديدة'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'اسم الأسرة'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إضافة'),
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
    final AsyncValue<List<HouseholdSummary>> state = ref.watch(
      householdsControllerProvider,
    );
    return AppScaffold(
      title: 'الاشتراكات',
      actions: <Widget>[
        IconButton(
          tooltip: 'أسرة جديدة',
          icon: const Icon(Icons.add),
          onPressed: () => _addHousehold(context, ref),
        ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الاشتراكات',
          onRetry: () => ref.invalidate(householdsControllerProvider),
        ),
        data: (List<HouseholdSummary> items) => items.isEmpty
            ? const EmptyState(
                message: 'مفيش أسر مسجّلة — ضيف أسرة بالزرّ فوق',
                icon: Icons.family_restroom,
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) => HouseholdTile(
                  key: ValueKey<String>(items[i].id),
                  household: items[i],
                  onRecordPayment: () => ref
                      .read(householdsControllerProvider.notifier)
                      .recordPayment(items[i]),
                ),
              ),
      ),
    );
  }
}
