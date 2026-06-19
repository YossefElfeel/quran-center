import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/subscription_repository.dart';
import '../../domain/payment_row.dart';

part 'household_payments_controller.g.dart';

/// سجلّ دفعات أسرة.
@riverpod
Future<List<PaymentRow>> householdPayments(Ref ref, String householdId) =>
    ref.watch(subscriptionRepositoryProvider).fetchPaymentHistory(householdId);
