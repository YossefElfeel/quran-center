import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/complaint.dart';
import '../controllers/feedback_controllers.dart';

/// صندوق الشكاوى للمدير — يقرا ويرد (SLA ٤٨ ساعة).
class ComplaintInboxScreen extends ConsumerWidget {
  const ComplaintInboxScreen({super.key});

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    Complaint c,
  ) async {
    final TextEditingController resp = TextEditingController(
      text: c.managerResponse ?? '',
    );
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('الرد على الشكوى'),
        content: TextField(
          controller: resp,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'ردّك'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إرسال الرد'),
          ),
        ],
      ),
    );
    final String text = resp.text;
    resp.dispose();
    if (ok == true) {
      await ref.read(complaintInboxProvider.notifier).respond(c.id, text);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Complaint>> state = ref.watch(complaintInboxProvider);
    return AppScaffold(
      title: 'صندوق الشكاوى',
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الشكاوى',
          onRetry: () => ref.invalidate(complaintInboxProvider),
        ),
        data: (List<Complaint> items) => items.isEmpty
            ? const EmptyState(message: 'مفيش شكاوى', icon: Icons.inbox)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final Complaint c = items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.md,
                    ),
                    child: ListTile(
                      title: Text(c.authorName ?? 'مستخدم'),
                      subtitle: Text(
                        '${complaintCategoriesAr[c.category] ?? c.category}: '
                        '${c.body}',
                      ),
                      trailing: TextButton(
                        onPressed: () => _respond(context, ref, c),
                        child: Text(c.isAnswered ? 'تعديل الرد' : 'رد'),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
