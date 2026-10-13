import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/settings/settings_repository.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/center_contact_button.dart';
import '../../data/subscription_repository.dart';
import '../../domain/payment_row.dart';
import '../controllers/my_subscription_controller.dart';

class HouseholdBilling {
  const HouseholdBilling(this.household, this.payments, this.paidMonths);
  final Map<String, dynamic> household;
  final List<PaymentRow> payments;
  final List<DateTime> paidMonths;
}

final FutureProvider<(List<HouseholdBilling>, bool)>
subscriptionDetailsProvider = FutureProvider((ref) async {
  final person = await ref.watch(currentPersonIdProvider.future);
  if (person == null) return (<HouseholdBilling>[], false);
  final rows = await ref
      .watch(supabaseClientProvider)
      .from('household_member')
      .select('household:household_id(id,name,monthly_amount,created_at)')
      .eq('person_id', person);
  final repo = ref.watch(subscriptionRepositoryProvider);
  final households = await Future.wait(
    rows.where((r) => r['household'] is Map<String, dynamic>).map((r) async {
      final household = r['household'] as Map<String, dynamic>;
      return HouseholdBilling(
        household,
        await repo.fetchPaymentHistory(household['id'] as String),
        await repo.fetchPaidMonths(
          household['id'] as String,
          DateTime(DateTime.now().year, DateTime.now().month - 11),
        ),
      );
    }),
  );
  return (households, await ref.watch(mySubscriptionActiveProvider.future));
});

class SubscriptionStatusView extends ConsumerStatefulWidget {
  const SubscriptionStatusView({super.key});
  @override
  ConsumerState<SubscriptionStatusView> createState() =>
      _SubscriptionStatusViewState();
}

class _SubscriptionStatusViewState
    extends ConsumerState<SubscriptionStatusView> {
  bool _refreshing = false;
  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      ref.invalidate(mySubscriptionActiveProvider);
      ref.invalidate(subscriptionDetailsProvider);
      await ref.read(subscriptionDetailsProvider.future);
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, AppL10n.of(context).subsStatusRefreshError);
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final state = ref.watch(subscriptionDetailsProvider);
    final phone =
        ref.watch(appSettingsProvider).asData?.value.centerPhone ?? '';
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          AppErrorView(message: l.subsLoadSubscriptionError, onRetry: _refresh),
      data: (data) => RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text(
              data.$2 ? l.subsActive : l.subsNeedsRenewal,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (data.$1.isEmpty) Text(l.subsNoHouseholdLinked),
            for (final billing in data.$1)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _HouseholdBillingCard(
                  key: ValueKey(billing),
                  billing: billing,
                ),
              ),
            const SizedBox(height: 24),
            AppButton(
              label: l.subsRefreshStatus,
              icon: Icons.refresh,
              isLoading: _refreshing,
              onPressed: _refresh,
            ),
            const SizedBox(height: 16),
            const CenterContactButton(),
            if (phone.isNotEmpty)
              TextButton(
                onPressed: () async {
                  try {
                    if (!await launchUrl(
                      Uri.https(
                        'wa.me',
                        '/${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
                      ),
                      mode: LaunchMode.externalApplication,
                    )) {
                      throw StateError('launch');
                    }
                  } catch (_) {
                    if (context.mounted) {
                      AppSnackbar.error(
                        context,
                        l.subsWhatsappOpenError(phone),
                      );
                    }
                  }
                },
                child: Text(l.subsAdminWhatsapp),
              ),
            if (data.$2)
              AppButton(
                label: l.subsSeeChildren,
                onPressed: () => context.go('/me'),
              ),
          ],
        ),
      ),
    );
  }
}

class _HouseholdBillingCard extends ConsumerStatefulWidget {
  const _HouseholdBillingCard({required this.billing, super.key});
  final HouseholdBilling billing;
  @override
  ConsumerState<_HouseholdBillingCard> createState() =>
      _HouseholdBillingCardState();
}

class _HouseholdBillingCardState extends ConsumerState<_HouseholdBillingCard> {
  HouseholdBilling get billing => widget.billing;
  final List<PaymentRow> _extra = [];
  bool _busy = false, _exhausted = false;
  String? _error;
  Future<void> _more() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(subscriptionRepositoryProvider)
          .fetchPaymentHistory(
            billing.household['id'] as String,
            offset: billing.payments.length + _extra.length,
          );
      if (mounted) {
        setState(() {
          _extra.addAll(page);
          _exhausted = page.length < 24;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).subsMorePaymentsError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(),
        created = DateTime.parse(billing.household['created_at'] as String);
    final paid = billing.paidMonths
        .map((month) => '${month.year}-${month.month}')
        .toSet();
    final l = AppL10n.of(context);
    final num monthlyAmount = billing.household['monthly_amount'] as num? ?? 0;
    // monthly_amount = 0 → الأسرة معفية: مفيش شهور مستحقة خالص.
    final bool exempt = monthlyAmount <= 0;
    final due = <DateTime>[];
    for (int i = 0; i < (exempt ? 0 : 12); i++) {
      final month = DateTime(now.year, now.month - i);
      if (month.isBefore(DateTime(created.year, created.month))) break;
      if (!paid.contains('${month.year}-${month.month}')) due.add(month);
    }
    String label(DateTime month) =>
        '${arabicNumber(month.month)}/${arabicNumber(month.year)}';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            billing.household['name'] as String,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            exempt
                ? l.subsExempt
                : l.subsMonthlyAmountPerMonth(arabicNumber(monthlyAmount)),
          ),
          const SizedBox(height: 16),
          if (exempt)
            Text(l.subsExemptNoDue)
          else ...<Widget>[
            Text(
              l.subsDueMonthsTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              due.isEmpty
                  ? l.subsNoDueMonths
                  : due
                        .map(label)
                        .join('، '), // l10n-ignore: Arabic list separator
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l.subsPaymentsLogTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (billing.payments.isEmpty) Text(l.subsNoPayments),
          for (final payment in [...billing.payments, ..._extra])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label(payment.periodMonth)),
              subtitle: Text(
                payment.voided
                    ? l.subsPaymentAmountVoided(arabicNumber(payment.amount))
                    : l.subsPaymentAmountPaid(arabicNumber(payment.amount)),
              ),
            ),
          if (_error != null)
            Text(_error!, style: TextStyle(color: context.palette.error)),
          if (billing.payments.length >= 24 && !_exhausted)
            AppButton(
              label: l.commonShowMore,
              isLoading: _busy,
              onPressed: _more,
            ),
        ],
      ),
    );
  }
}
