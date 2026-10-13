import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_confirm_sheet.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/subscription_repository.dart';
import '../../domain/household_summary.dart';
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
      final double amount = parseLocalizedDouble(_amount.text)!;
      if (!await showAppConfirmSheet(
        context: context,
        title: 'تأكيد الدفعة',
        message:
            '${widget.household.name} — ${arabicNumber(_month.month)}/${arabicNumber(_month.year)} — ${arabicNumber(amount)} ج.م',
        confirmLabel: 'تسجيل الدفعة',
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
          'الدفعة اتسجّلت',
          actionLabel: 'تراجع',
          onAction: () async {
            try {
              await repo.voidPayment(id, 'تراجع بعد تسجيل الدفعة');
              if (feedbackContext.mounted) {
                refresh();
                AppSnackbar.success(feedbackContext, 'الدفعة اتلغت');
              }
            } catch (_) {
              if (feedbackContext.mounted) {
                AppSnackbar.error(
                  feedbackContext,
                  'تعذّر إلغاء الدفعة — راجع الإدارة',
                );
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
              ? 'الشهر ده مدفوع بالفعل'
              : 'تعذّر تسجيل الدفعة — جرّب تاني',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          widget.household.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
            'الشهر: ${arabicNumber(_month.month)}/${arabicNumber(_month.year)}',
          ),
        ),
        AppTextField(
          controller: _amount,
          label: 'المبلغ (ج.م)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (String? v) =>
              v == null ||
                  parseLocalizedDouble(v) == null ||
                  !parseLocalizedDouble(v)!.isFinite ||
                  parseLocalizedDouble(v)! < 0 ||
                  (parseLocalizedDouble(v)! * 100 -
                              (parseLocalizedDouble(v)! * 100).round())
                          .abs() >
                      .000001
              ? 'اكتب مبلغ صحيح'
              : null,
        ),
        const SizedBox(height: 16),
        AppSelectField<String>(
          label: 'طريقة الدفع',
          value: _method,
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem(value: 'cash', child: Text('كاش')),
            DropdownMenuItem(value: 'instapay', child: Text('InstaPay')),
            DropdownMenuItem(value: 'other', child: Text('أخرى')),
          ],
          onChanged: (String? v) => setState(() => _method = v ?? 'cash'),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'مراجعة وتسجيل الدفعة',
          isLoading: _busy,
          onPressed: _save,
        ),
      ],
    ),
  );
}
