import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_date.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
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

/// صندوق الشكاوى للمدير — يقرا ويرد (SLA ٤٨ ساعة).
class ComplaintInboxScreen extends ConsumerWidget {
  const ComplaintInboxScreen({super.key});

  void _openDetails(BuildContext context, WidgetRef ref, Complaint complaint) {
    final AppL10n l = AppL10n.of(context);
    showAppModalSheet<void>(
      context: context,
      title: l.fbkComplaintDetails,
      builder: (BuildContext sheetContext) => ComplaintDetailContent(
        complaint: complaint,
        action: AppButton(
          label: complaint.isAnswered ? l.fbkEditResponse : l.fbkRespond,
          icon: Icons.reply,
          onPressed: () async {
            Navigator.of(sheetContext).pop();
            await Future<void>.delayed(Duration.zero);
            if (context.mounted) await _respond(context, ref, complaint);
          },
        ),
      ),
    );
  }

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    Complaint complaint,
  ) => showAppModalSheet<void>(
    context: context,
    title: 'الرد على الشكوى',
    builder: (_) => ComplaintComposeSheet(complaint: complaint),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<Complaint>> state = ref.watch(complaintInboxProvider);
    return AppScaffold(
      title: l.fbkInboxTitle,
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.fbkLoadComplaintsError,
          onRetry: () => ref.invalidate(complaintInboxProvider),
        ),
        data: (List<Complaint> items) => items.isEmpty
            ? EmptyState(
                message: l.fbkNoComplaints,
                icon: Icons.inbox,
                action: TextButton(
                  onPressed: () => ref.invalidate(complaintInboxProvider),
                  child: const Text('تحديث البيانات'),
                ),
              )
            : AppRefreshIndicator(
                onRefresh: () async => ref.invalidate(complaintInboxProvider),
                child: AppPagedList<Complaint>(
                  items: items,
                  loadPage: (offset) => ref
                      .read(feedbackRepositoryProvider)
                      .fetchInbox(offset: offset),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),

                  itemBuilder: (BuildContext context, Complaint item, int i) {
                    final Complaint c = item;
                    return AppListCard(
                      leadingIcon: Icons.support_agent,
                      title: c.authorName ?? l.fbkUnknownUser,
                      subtitle:
                          '${l.fbkComplaintNumber(c.referenceNumber)} · '
                          '${arabicDateTimeLabel(c.createdAt)}\n'
                          '${complaintCategoriesAr[c.category] ?? c.category}: ${c.body}',
                      onTap: () => _openDetails(context, ref, c),
                      trailing: AppStatusBadge(
                        label: c.statusAr,
                        kind: c.isAnswered
                            ? AppStatusKind.success
                            : AppStatusKind.warning,
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
