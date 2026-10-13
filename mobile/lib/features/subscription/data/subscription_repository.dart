import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/household_member_row.dart';
import '../domain/household_summary.dart';
import '../domain/payment_row.dart';
import '../domain/person_option.dart';
import '../domain/subscription_logic.dart';

part 'subscription_repository.g.dart';

/// اشتراكات الأسر: قايمة بالحالة + إنشاء أسرة + تسجيل دفعة كاش.
class SubscriptionRepository {
  SubscriptionRepository(this._client);

  final SupabaseClient _client;

  /// حجم الصفحة لقايمة الأسر (الـ RPC بيرجّع جدول، فـ PostgREST بيدعم
  /// الفلترة والـ range عليه من غير ما نعدّل الـ SQL).
  static const int householdsPageSize = 50;

  Future<List<HouseholdSummary>> fetchHouseholds({
    String query = '',
    int offset = 0,
    int limit = householdsPageSize,
  }) async {
    PostgrestFilterBuilder<dynamic> q = _client.rpc('households_with_status');
    final String term = query.trim().replaceAll(RegExp(r'[,().%*]'), '');
    if (term.isNotEmpty) q = q.ilike('name', '%$term%');
    final dynamic res = await q
        .order('name', ascending: true)
        .range(offset, offset + limit - 1)
        .timeout(const Duration(seconds: 12));
    final DateTime today = DateTime.now();
    return (res as List<dynamic>)
        .map((dynamic r) => _household(r as Map<String, dynamic>, today))
        .toList();
  }

  /// أسرة واحدة بالحالة (من غير ما نحمّل القايمة كلها).
  Future<HouseholdSummary?> fetchHousehold(String id) async {
    final dynamic res = await _client
        .rpc('households_with_status')
        .eq('id', id)
        .maybeSingle()
        .timeout(const Duration(seconds: 12));
    if (res == null) return null;
    return _household(res as Map<String, dynamic>, DateTime.now());
  }

  /// الأسر المتأخّرة فعلًا (فلترة على السيرفر بنفس منطق
  /// [deriveSubscriptionStatus]) — للهوم، عشان مايفوتهاش أسرة بعد أول صفحة.
  Future<List<HouseholdSummary>> fetchOverdueHouseholds({
    int limit = householdsPageSize,
  }) async {
    final DateTime today = DateTime.now();
    final DateTime current = DateTime(today.year, today.month);
    // متأخّر = آخر شهر مدفوع قبل الشهر الحالي، إلا لو شهر واحد بس وإحنا
    // لسه في فترة السماح.
    final DateTime cutoff = today.day <= defaultGraceDays
        ? DateTime(current.year, current.month - 1)
        : current;
    final String cutoffIso =
        '${cutoff.year.toString().padLeft(4, '0')}-${cutoff.month.toString().padLeft(2, '0')}-01';
    final dynamic res = await _client
        .rpc('households_with_status')
        .not('last_paid_month', 'is', null)
        .lt('last_paid_month', cutoffIso)
        .order('name', ascending: true)
        .limit(limit)
        .timeout(const Duration(seconds: 12));
    return (res as List<dynamic>)
        .map((dynamic r) => _household(r as Map<String, dynamic>, today))
        .toList();
  }

  HouseholdSummary _household(Map<String, dynamic> m, DateTime today) {
    final String? lastPaid = m['last_paid_month'] as String?;
    final DateTime? lastPaidMonth = lastPaid != null
        ? DateTime.parse(lastPaid)
        : null;
    return HouseholdSummary(
      id: m['id'] as String,
      name: m['name'] as String,
      monthlyAmount: (m['monthly_amount'] as num).toDouble(),
      status: deriveSubscriptionStatus(
        lastPaidMonth: lastPaidMonth,
        today: today,
      ),
      lastPaidMonth: lastPaidMonth,
    );
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

  Future<String> recordPayment({
    required String householdId,
    required double amount,
    required DateTime month,
    required String method,
    String? recordedBy,
  }) async {
    final Map<String, dynamic> row = await _client
        .from('subscription_payment')
        .insert(<String, dynamic>{
          'household_id': householdId,
          'amount': amount,
          'period_month':
              '${month.year}-${month.month.toString().padLeft(2, '0')}-01',
          'method': method,
          'recorded_by': ?recordedBy,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> voidPayment(String id, String reason) async {
    await _client
        .from('subscription_payment')
        .update(<String, dynamic>{'voided': true, 'void_reason': reason})
        .eq('id', id)
        .select('id')
        .single();
  }

  /// سجلّ دفعات أسرة (الأحدث أولًا) — لتفصيل بلاطة الاشتراك.
  Future<List<PaymentRow>> fetchPaymentHistory(
    String householdId, {
    int offset = 0,
  }) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('subscription_payment')
        .select('period_month, amount, paid_at, voided')
        .eq('household_id', householdId)
        .order('period_month', ascending: false)
        .order('paid_at', ascending: false)
        .order('id')
        .range(offset, offset + 23)
        .timeout(const Duration(seconds: 12));
    return rows.map(PaymentRow.fromMap).toList();
  }

  Future<List<DateTime>> fetchPaidMonths(
    String householdId,
    DateTime since,
  ) async {
    final rows = await _client
        .from('subscription_payment')
        .select('period_month')
        .eq('household_id', householdId)
        .eq('voided', false)
        .gte(
          'period_month',
          '${since.year}-${since.month.toString().padLeft(2, '0')}-01',
        )
        .order('period_month', ascending: false)
        .timeout(const Duration(seconds: 12));
    return rows
        .map((row) => DateTime.parse(row['period_month'] as String))
        .toList();
  }

  /// هل اشتراك المستخدم الحالي (ولي الأمر) نشط؟ (لبوابة الوصول).
  Future<bool> mySubscriptionActive() async {
    final dynamic res = await _client
        .rpc('my_subscription_active')
        .timeout(const Duration(seconds: 12));
    return (res as bool?) ?? false;
  }

  /// كل الأشخاص (لاختيار فرد يتضاف للأسرة).
  Future<List<PersonOption>> fetchAllPersons({String query = ''}) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('person')
        .select('id, full_name')
        .ilike('full_name', '%${query.trim()}%')
        .order('full_name', ascending: true)
        .range(0, 49)
        .timeout(const Duration(seconds: 12));
    return rows
        .map(
          (Map<String, dynamic> r) => PersonOption(
            personId: r['id'] as String,
            fullName: r['full_name'] as String,
          ),
        )
        .toList();
  }

  Future<List<HouseholdMemberRow>> fetchHouseholdMembers(
    String householdId,
  ) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('household_member')
        .select('role, person:person_id(full_name)')
        .eq('household_id', householdId)
        .timeout(const Duration(seconds: 12));
    return rows.map(HouseholdMemberRow.fromMap).toList();
  }

  Future<void> addHouseholdMember({
    required String householdId,
    required String personId,
    required String role,
  }) async {
    try {
      await _client.from('household_member').insert(<String, dynamic>{
        'household_id': householdId,
        'person_id': personId,
        'role': role,
      });
    } on PostgrestException catch (e) {
      // 23505 = unique_violation: الشخص في أسرة واحدة بس (household_member_person_unique).
      if (e.code == '23505') {
        throw const ValidationException.reason(
          AppErrorReason.alreadyInHousehold,
        );
      }
      rethrow;
    }
  }
}

@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) =>
    SubscriptionRepository(ref.watch(supabaseClientProvider));
