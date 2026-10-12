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
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/complaint.dart';
import '../controllers/feedback_controllers.dart';
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
    Complaint c,
  ) async {
    final AppL10n l = AppL10n.of(context);
    final TextEditingController resp = TextEditingController(
      text: c.managerResponse ?? '',
    );
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.fbkRespondDialogTitle),
        content: AppTextField(
          controller: resp,
          autofocus: true,
          maxLines: 5,
          label: l.fbkResponseLabel,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.fbkSendResponse),
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
            ? EmptyState(message: l.fbkNoComplaints, icon: Icons.inbox)
            : AppRefreshIndicator(
                onRefresh: () async => ref.invalidate(complaintInboxProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) {
                    final Complaint c = items[i];
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
