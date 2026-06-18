import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/complaint.dart';
import '../controllers/feedback_controllers.dart';

/// شكاوي المستخدم — يرفع شكوى ويشوف الردود.
class MyComplaintsScreen extends ConsumerWidget {
  const MyComplaintsScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    String category = 'other';
    final TextEditingController body = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('شكوى جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'النوع'),
              items: complaintCategoriesAr.entries
                  .map(
                    (MapEntry<String, String> e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (String? v) => category = v ?? 'other',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: body,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'تفاصيل الشكوى'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    final String text = body.text;
    body.dispose();
    if (ok == true) {
      await ref
          .read(myComplaintsProvider.notifier)
          .add(category: category, body: text);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Complaint>> state = ref.watch(myComplaintsProvider);
    return AppScaffold(
      title: 'الشكاوى',
      actions: <Widget>[
        IconButton(
          tooltip: 'شكوى جديدة',
          icon: const Icon(Icons.add),
          onPressed: () => _add(context, ref),
        ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الشكاوى',
          onRetry: () => ref.invalidate(myComplaintsProvider),
        ),
        data: (List<Complaint> items) => items.isEmpty
            ? const EmptyState(
                message: 'مفيش شكاوى — رقم المدير متاح لو محتاج',
                icon: Icons.support_agent,
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) =>
                    _ComplaintCard(complaint: items[i]),
              ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    complaintCategoriesAr[complaint.category] ??
                        complaint.category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  complaint.statusAr,
                  style: TextStyle(
                    color: complaint.isAnswered
                        ? AppColors.success
                        : AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(complaint.body),
            if (complaint.isAnswered) ...<Widget>[
              const Divider(),
              Text(
                'ردّ المدير: ${complaint.managerResponse}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
