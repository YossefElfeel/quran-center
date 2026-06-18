import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/household_summary.dart';
import '../domain/subscription_logic.dart';

part 'subscription_repository.g.dart';

/// اشتراكات الأسر: قايمة بالحالة + إنشاء أسرة + تسجيل دفعة كاش.
class SubscriptionRepository {
  SubscriptionRepository(this._client);

  final SupabaseClient _client;

  Future<List<HouseholdSummary>> fetchHouseholds() async {
    final dynamic res = await _client.rpc('households_with_status');
    final List<dynamic> rows = res as List<dynamic>;
    final DateTime today = DateTime.now();
    return rows.map((dynamic r) {
      final Map<String, dynamic> m = r as Map<String, dynamic>;
      final String? lastPaid = m['last_paid_month'] as String?;
      return HouseholdSummary(
        id: m['id'] as String,
        name: m['name'] as String,
        monthlyAmount: (m['monthly_amount'] as num).toDouble(),
        status: deriveSubscriptionStatus(
          lastPaidMonth: lastPaid != null ? DateTime.parse(lastPaid) : null,
          today: today,
        ),
      );
    }).toList();
  }

  Future<void> createHousehold(String name) async {
    await _client.from('household').insert(<String, dynamic>{'name': name});
  }

  /// يسجّل دفعة كاش لشهر النهارده.
  Future<void> recordCurrentMonthPayment({
    required String householdId,
    required double amount,
    String? recordedBy,
  }) async {
    final DateTime now = DateTime.now();
    final String periodMonth =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-01';
    await _client.from('subscription_payment').insert(<String, dynamic>{
      'household_id': householdId,
      'amount': amount,
      'period_month': periodMonth,
      'recorded_by': ?recordedBy,
    });
  }

  /// هل اشتراك المستخدم الحالي (ولي الأمر) نشط؟ (لبوابة الوصول).
  Future<bool> mySubscriptionActive() async {
    final dynamic res = await _client.rpc('my_subscription_active');
    return (res as bool?) ?? false;
  }
}

@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) =>
    SubscriptionRepository(ref.watch(supabaseClientProvider));
