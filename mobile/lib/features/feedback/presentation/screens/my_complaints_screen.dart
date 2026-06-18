import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

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
    final AppL10n l = AppL10n.of(context);
    String category = 'other';
    final TextEditingController body = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.fbkNewComplaint),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: InputDecoration(labelText: l.fbkCategory),
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
              decoration: InputDecoration(labelText: l.fbkComplaintDetails),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.fbkSend),
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
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<Complaint>> state = ref.watch(myComplaintsProvider);
    return AppScaffold(
      title: l.fbkMyComplaintsTitle,
      actions: <Widget>[
        IconButton(
          tooltip: l.fbkNewComplaint,
          icon: const Icon(Icons.add),
          onPressed: () => _add(context, ref),
        ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.fbkLoadComplaintsError,
          onRetry: () => ref.invalidate(myComplaintsProvider),
        ),
        data: (List<Complaint> items) => items.isEmpty
            ? EmptyState(
                message: l.fbkNoComplaintsParent,
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
    final AppL10n l = AppL10n.of(context);
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
                '${l.fbkManagerResponseLabel}: ${complaint.managerResponse}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
