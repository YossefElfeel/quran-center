import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_confirm_sheet.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/subscription_repository.dart';
import '../../domain/household_summary.dart';
import '../../domain/payment_amount.dart';
import '../controllers/household_payments_controller.dart';
import '../controllers/households_controller.dart';

class RecordPaymentSheet extends ConsumerStatefulWidget {
  const RecordPaymentSheet({
    required this.household,
    required this.feedbackContext,
    super.key,
  });
  final HouseholdSummary household;
  final BuildContext feedbackContext;
  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.household.monthlyAmount.toString(),
  );
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _method = 'cash';
  bool _busy = false;
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final BuildContext feedbackContext = widget.feedbackContext;
    final ProviderContainer container = ProviderScope.containerOf(context);
    void refresh() {
      container.invalidate(householdsControllerProvider);
      container.invalidate(householdPaymentsProvider(widget.household.id));
    }

    try {
      final double? amount = parsePaymentAmount(_amount.text);
      if (amount == null) return;
      final AppL10n l = AppL10n.of(context);
      if (!await showAppConfirmSheet(
        context: context,
        title: l.subsConfirmPaymentTitle,
        message: l.subsPaymentConfirmMessage(
          widget.household.name,
          arabicNumber(_month.month),
          arabicNumber(_month.year),
          arabicAmount(amount),
        ),
        confirmLabel: l.subsConfirmPaymentAction,
        destructive: false,
      )) {
        return;
      }
      final String? person = await ref.read(currentPersonIdProvider.future);
      final SubscriptionRepository repo = ref.read(
        subscriptionRepositoryProvider,
      );
      final String id = await repo.recordPayment(
        householdId: widget.household.id,
        amount: amount,
        month: _month,
        method: _method,
        recordedBy: person,
      );
      refresh();
      if (mounted && feedbackContext.mounted) {
        AppSnackbar.success(
          feedbackContext,
          l.subsPaymentRecorded,
          actionLabel: l.subsUndo,
          onAction: () async {
            try {
              await repo.voidPayment(
                id,
                'تراجع بعد تسجيل الدفعة', // l10n-ignore: void reason stored server-side
              );
              if (feedbackContext.mounted) {
                refresh();
                AppSnackbar.success(feedbackContext, l.subsPaymentVoided);
              }
            } catch (_) {
              if (feedbackContext.mounted) {
                AppSnackbar.error(feedbackContext, l.subsVoidPaymentError);
              }
            }
          },
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          e.toString().contains('23505')
              ? AppL10n.of(context).subsMonthAlreadyPaid
              : AppL10n.of(context).subsRecordPaymentError,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // The shared sheet already shows the title; this line only names the
          // household the payment is for.
          Text(
            widget.household.name,
            style: AppTextStyles.bodyMd.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () async {
                    final DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: _month,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(
                        DateTime.now().year,
                        DateTime.now().month + 1,
                        0,
                      ),
                    );
                    if (date != null && mounted) {
                      setState(() => _month = DateTime(date.year, date.month));
                    }
                  },
            child: Text(
              l.subsPaymentMonthLabel(
                arabicNumber(_month.month),
                arabicNumber(_month.year),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _amount,
            label: l.subsAmountLabel,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (String? v) {
              if (parsePaymentAmount(v) != null) return null;
              final double? raw = v == null ? null : parseLocalizedDouble(v);
              return raw != null && raw <= 0
                  ? l.subsAmountPositive
                  : l.subsAmountInvalid;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppSelectField<String>(
            label: l.subsPaymentMethodLabel,
            value: _method,
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem(value: 'cash', child: Text(l.subsMethodCash)),
              const DropdownMenuItem(
                value: 'instapay',
                child: Text('InstaPay'),
              ),
              DropdownMenuItem(value: 'other', child: Text(l.subsMethodOther)),
            ],
            onChanged: (String? v) => setState(() => _method = v ?? 'cash'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l.subsReviewAndRecord,
            isLoading: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
