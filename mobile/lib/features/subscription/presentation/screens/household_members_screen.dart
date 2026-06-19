import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_date.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/household_member_row.dart';
import '../../domain/payment_row.dart';
import '../controllers/household_members_controller.dart';
import '../controllers/household_payments_controller.dart';
import '../widgets/add_household_member_sheet.dart';

/// أفراد أسرة (أولياء أمور + طلبة) — للأدمن.
class HouseholdMembersScreen extends ConsumerWidget {
  const HouseholdMembersScreen({
    required this.householdId,
    required this.householdName,
    super.key,
  });

  final String householdId;
  final String householdName;

  void _add(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) =>
          AddHouseholdMemberSheet(householdId: householdId),
    );
  }

  void _openPayments(BuildContext context) {
    showAppModalSheet<void>(
      context: context,
      title: AppL10n.of(context).subsPaymentHistory,
      builder: (BuildContext _) => _PaymentsSheet(householdId: householdId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<HouseholdMemberRow>> state = ref.watch(
      householdMembersControllerProvider(householdId),
    );
    return AppScaffold(
      title: householdName,
      actions: <Widget>[
        IconButton(
          tooltip: l.subsPaymentHistory,
          icon: const Icon(Icons.receipt_long),
          onPressed: () => _openPayments(context),
        ),
        IconButton(
          tooltip: l.subsAddMember,
          icon: const Icon(Icons.person_add),
          onPressed: () => _add(context),
        ),
      ],
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.subsMembersLoadError,
          onRetry: () =>
              ref.invalidate(householdMembersControllerProvider(householdId)),
        ),
        data: (List<HouseholdMemberRow> items) => items.isEmpty
            ? EmptyState(message: l.subsNoMembers, icon: Icons.group_add)
            : AppRefreshIndicator(
                onRefresh: () async => ref.invalidate(
                  householdMembersControllerProvider(householdId),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) {
                    final HouseholdMemberRow m = items[i];
                    return AppListCard(
                      leadingIcon: m.role == 'guardian'
                          ? Icons.person
                          : Icons.child_care,
                      title: m.personName,
                      subtitle: m.roleAr,
                    );
                  },
                ),
              ),
      ),
    );
  }
}

/// محتوى شيت سجلّ الدفعات: كل دفعة (الشهر + المبلغ + تاريخ الدفع).
class _PaymentsSheet extends ConsumerWidget {
  const _PaymentsSheet({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final AsyncValue<List<PaymentRow>> state = ref.watch(
      householdPaymentsProvider(householdId),
    );
    return state.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(l.subsPaymentsLoadError),
      ),
      data: (List<PaymentRow> items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l.subsNoPayments,
              style: AppTextStyles.bodyLg.copyWith(color: p.textSecondary),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final PaymentRow pay in items) _PaymentRowTile(payment: pay),
          ],
        );
      },
    );
  }
}

class _PaymentRowTile extends StatelessWidget {
  const _PaymentRowTile({required this.payment});

  final PaymentRow payment;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final Color amountColor = payment.voided ? p.textSecondary : p.success;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Icon(
            payment.voided ? Icons.money_off : Icons.check_circle,
            color: amountColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              arabicMonthLabel(payment.periodMonth),
              style: AppTextStyles.bodyLg.copyWith(color: p.textPrimary),
            ),
          ),
          Text(
            l.subsMonthlyAmount(arabicNumber(payment.amount.round())),
            style: AppTextStyles.titleMd.copyWith(
              color: amountColor,
              fontWeight: FontWeight.bold,
              decoration: payment.voided ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
