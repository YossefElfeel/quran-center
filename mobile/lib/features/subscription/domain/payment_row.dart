/// دفعة اشتراك في سجلّ الأسرة.
class PaymentRow {
  const PaymentRow({
    required this.periodMonth,
    required this.amount,
    this.paidAt,
    this.voided = false,
  });

  factory PaymentRow.fromMap(Map<String, dynamic> map) => PaymentRow(
    periodMonth: DateTime.parse(map['period_month'] as String),
    amount: (map['amount'] as num).toDouble(),
    paidAt: map['paid_at'] != null
        ? DateTime.parse(map['paid_at'] as String)
        : null,
    voided: (map['voided'] as bool?) ?? false,
  );

  /// الشهر اللي الدفعة بتغطّيه.
  final DateTime periodMonth;
  final double amount;

  /// وقت الدفع الفعلي (أو null).
  final DateTime? paidAt;

  /// ملغيّة؟ (تتعرض مشطوبة).
  final bool voided;
}
