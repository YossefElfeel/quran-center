import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_confirm_sheet.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../subscription/domain/household_summary.dart';
import '../../../subscription/presentation/controllers/households_controller.dart';
import '../../../subscription/presentation/widgets/record_payment_sheet.dart';
import '../../../user_invite/presentation/screens/invite_user_screen.dart';
import '../../domain/guardian_link_row.dart';
import '../controllers/guardian_links_controller.dart';
import '../family_labels.dart';
import '../widgets/add_guardian_link_sheet.dart';
import '../widgets/edit_guardian_sheet.dart';

/// يفتح دعوة الدخول لولي أمر موجود، وبعد الرجوع يحدّث القائمة (حالة الدخول).
Future<void> _openInvite(
  BuildContext context,
  WidgetRef ref,
  GuardianLinkRow r,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => InviteUserScreen(
        existingPersonId: r.guardianId,
        existingName: r.guardianName,
        existingRole: 'parent',
      ),
    ),
  );
  ref.invalidate(guardianLinksControllerProvider);
}

/// الأدمن — ربط أولياء الأمور بالأطفال (عشان يدخلوا بوابة المتابعة).
class GuardianLinksScreen extends ConsumerWidget {
  const GuardianLinksScreen({super.key});

  void _add(BuildContext context) {
    showAppModalSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => const AddGuardianLinkSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<GuardianLinkRow>> state = ref.watch(
      guardianLinksControllerProvider,
    );
    return AppScaffold(
      title: l.famGuardianLinksTitle,
      actions: <Widget>[
        IconButton(
          tooltip: l.famNewLink,
          icon: const Icon(Icons.add),
          onPressed: () => _add(context),
        ),
      ],
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.famLinksLoadError,
          onRetry: () => ref.invalidate(guardianLinksControllerProvider),
        ),
        data: (List<GuardianLinkRow> items) => items.isEmpty
            ? EmptyState(
                message: l.famNoLinks,
                icon: Icons.link_off,
                action: AppButton(
                  label: l.famNewLink,
                  onPressed: () => _add(context),
                ),
              )
            : AppRefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(guardianLinksControllerProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) {
                    final GuardianLinkRow r = items[i];
                    return AppListCard(
                      key: ValueKey<String>('${r.guardianId}-${r.studentId}'),
                      leadingIcon: Icons.link,
                      trailing: _GuardianFixAction(row: r),
                      title: r.guardianName,
                      subtitle: l.famLinkRowSubtitle(
                        r.relationLabel(l),
                        r.childName,
                        r.hasLogin ? '✓' : '✗',
                        r.householdId != null ? '✓' : '✗',
                        r.subscriptionActive
                            ? l.famSubscriptionActive
                            : l.famSubscriptionNeedsRenewal,
                        l.famChildrenCount(
                          r.childrenCount,
                          '${r.childrenCount}',
                        ),
                      ),
                      onTap: () => showAppModalSheet<void>(
                        context: context,
                        title: r.guardianName,
                        builder: (BuildContext sheetContext) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            AppButton(
                              label: l.famEditDataHousehold,
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                showAppModalSheet<void>(
                                  context: context,
                                  title: l.famEditGuardian,
                                  builder: (_) => EditGuardianSheet(row: r),
                                );
                              },
                            ),
                            if (!r.hasLogin)
                              AppButton(
                                label: l.famCreateLoginInvite,
                                onPressed: () async {
                                  Navigator.of(sheetContext).pop();
                                  await _openInvite(context, ref, r);
                                },
                              ),
                            if (r.householdId != null)
                              AppButton(
                                label: l.famPaymentManageHousehold,
                                onPressed: () => context.push(
                                  '/admin/household/${r.householdId}/members?name=${Uri.encodeComponent(r.householdName ?? l.famHouseholdTitle)}',
                                ),
                              ),
                            TextButton(
                              onPressed: () async {
                                if (!await showAppConfirmSheet(
                                  context: sheetContext,
                                  title: l.famUnlinkConfirmTitle,
                                  confirmLabel: l.famUnlinkConfirm,
                                  message: l.famUnlinkConfirmMessage,
                                )) {
                                  return;
                                }
                                try {
                                  await ref
                                      .read(supabaseClientProvider)
                                      .from('guardian_link')
                                      .delete()
                                      .eq('guardian_person_id', r.guardianId)
                                      .eq('student_person_id', r.studentId);
                                  ref.invalidate(
                                    guardianLinksControllerProvider,
                                  );
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                } catch (_) {
                                  if (sheetContext.mounted) {
                                    AppSnackbar.error(
                                      sheetContext,
                                      l.famUnlinkError,
                                    );
                                  }
                                }
                              },
                              child: Text(l.famUnlinkChild),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

/// إصلاح مباشر لأول بند ناقص في قائمة تجهيز ولي الأمر (أسرة ← دعوة ← دفعة)
/// بدل شيت عام. الأسرة الأول لأن دعوة ولي الأمر بتتطلّب عضوية أسرة.
class _GuardianFixAction extends ConsumerWidget {
  const _GuardianFixAction({required this.row});

  final GuardianLinkRow row;

  Future<void> _recordPayment(BuildContext context, WidgetRef ref) async {
    final String householdId = row.householdId!;
    try {
      final List<HouseholdSummary> households = await ref.read(
        householdsControllerProvider.future,
      );
      final HouseholdSummary household = households.firstWhere(
        (HouseholdSummary h) => h.id == householdId,
      );
      if (!context.mounted) return;
      await showAppModalSheet<void>(
        context: context,
        title: AppL10n.of(context).famFixPayment,
        builder: (_) =>
            RecordPaymentSheet(household: household, feedbackContext: context),
      );
      ref.invalidate(guardianLinksControllerProvider);
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.error(context, AppL10n.of(context).famHouseholdLoadError);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    if (row.householdId == null) {
      return TextButton(
        onPressed: () async {
          await showAppModalSheet<void>(
            context: context,
            title: l.famEditGuardian,
            builder: (_) => EditGuardianSheet(row: row),
          );
        },
        child: Text(l.famFixHousehold),
      );
    }
    if (!row.hasLogin) {
      return TextButton(
        onPressed: () => _openInvite(context, ref, row),
        child: Text(l.famFixInvite),
      );
    }
    if (!row.subscriptionActive) {
      return TextButton(
        onPressed: () => _recordPayment(context, ref),
        child: Text(l.famFixPayment),
      );
    }
    return Icon(Icons.check_circle, color: context.palette.success);
  }
}
