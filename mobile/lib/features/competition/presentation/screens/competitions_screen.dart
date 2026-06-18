import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/competition_models.dart';
import '../controllers/competition_controllers.dart';

/// قايمة المسابقات (الأدمن يضيف؛ الكل يفتح).
class CompetitionsScreen extends ConsumerWidget {
  const CompetitionsScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final TextEditingController name = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('مسابقة جديدة'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'اسم المسابقة'),
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
    final String text = name.text;
    name.dispose();
    if (ok == true) await ref.read(competitionsProvider.notifier).create(text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<CompetitionRow>> state = ref.watch(
      competitionsProvider,
    );
    return AppScaffold(
      title: 'المسابقات',
      actions: <Widget>[
        IconButton(
          tooltip: 'مسابقة جديدة',
          icon: const Icon(Icons.add),
          onPressed: () => _add(context, ref),
        ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل المسابقات',
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (List<CompetitionRow> items) => items.isEmpty
            ? const EmptyState(
                message: 'مفيش مسابقات — ضيف وحدة بالزرّ فوق',
                icon: Icons.emoji_events,
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) => Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs,
                    horizontal: AppSpacing.md,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.emoji_events,
                      color: AppColors.accent,
                    ),
                    title: Text(items[i].name),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.go(
                      Routes.competitionDetail(items[i].id, items[i].name),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
