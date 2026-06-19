import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_text_field.dart';
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
            AppTextField(
              controller: body,
              autofocus: true,
              maxLines: 4,
              label: l.fbkComplaintDetails,
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
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.fbkLoadComplaintsError,
          onRetry: () => ref.invalidate(myComplaintsProvider),
        ),
        data: (List<Complaint> items) => items.isEmpty
            ? EmptyState(
                message: l.fbkNoComplaintsParent,
                icon: Icons.support_agent,
              )
            : AppRefreshIndicator(
                onRefresh: () async => ref.invalidate(myComplaintsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) =>
                      _ComplaintCard(complaint: items[i]),
                ),
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
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    complaintCategoriesAr[complaint.category] ??
                        complaint.category,
                    style: AppTextStyles.titleMd.copyWith(
                      color: p.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AppStatusBadge(
                  label: complaint.statusAr,
                  kind: complaint.isAnswered
                      ? AppStatusKind.success
                      : AppStatusKind.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              complaint.body,
              style: AppTextStyles.bodyMd.copyWith(color: p.textPrimary),
            ),
            if (complaint.isAnswered) ...<Widget>[
              const Divider(),
              Text(
                '${l.fbkManagerResponseLabel}: ${complaint.managerResponse}',
                style: AppTextStyles.bodyMd.copyWith(color: p.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
