import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_date.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_paged_list.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/feedback_repository.dart';
import '../../domain/complaint.dart';
import '../controllers/feedback_controllers.dart';
import '../widgets/complaint_compose_sheet.dart';
import '../widgets/complaint_detail_content.dart';

/// شكاوي المستخدم — يرفع شكوى ويشوف الردود.
class MyComplaintsScreen extends ConsumerWidget {
  const MyComplaintsScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) =>
      showAppModalSheet<void>(
        context: context,
        title: 'شكوى جديدة',
        builder: (_) => const ComplaintComposeSheet(),
      );

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
                action: TextButton(
                  onPressed: () => _add(context, ref),
                  child: Text(l.fbkNewComplaint),
                ),
                icon: Icons.support_agent,
              )
            : AppRefreshIndicator(
                onRefresh: () async => ref.invalidate(myComplaintsProvider),
                child: AppPagedList<Complaint>(
                  items: items,
                  loadPage: (offset) => ref
                      .read(feedbackRepositoryProvider)
                      .fetchMyComplaints(offset: offset),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),

                  itemBuilder: (BuildContext context, Complaint item, int i) =>
                      _ComplaintCard(complaint: item),
                ),
              ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint});

  final Complaint complaint;

  void _openDetails(BuildContext context) {
    showAppModalSheet<void>(
      context: context,
      title: AppL10n.of(context).fbkComplaintDetails,
      builder: (BuildContext _) => ComplaintDetailContent(complaint: complaint),
    );
  }

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
        onTap: () => _openDetails(context),
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
              '${l.fbkComplaintNumber(complaint.referenceNumber)} · '
              '${arabicDateTimeLabel(complaint.createdAt)}',
              style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              complaint.body,
              style: AppTextStyles.bodyMd.copyWith(color: p.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
