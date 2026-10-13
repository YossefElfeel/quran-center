import '../../../core/utils/arabic_numerals.dart';

/// يحلّل مبلغ الدفعة (أرقام عربية/غربية): لازم يكون رقم موجب بحد أقصى قرشين
/// عشريين، وإلا null. دفعة بصفر كانت بتحجز الشهر عبر الفهرس الفريد.
double? parsePaymentAmount(String? input) {
  final double? amount = input == null ? null : parseLocalizedDouble(input);
  if (amount == null || !amount.isFinite || amount <= 0) return null;
  if ((amount * 100 - (amount * 100).round()).abs() > .000001) return null;
  return amount;
}
