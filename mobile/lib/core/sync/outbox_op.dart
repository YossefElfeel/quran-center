import 'dart:convert';

/// نوع عملية الكتابة في طابور الإرسال — كل نوع له منطق إرسال مختلف.
enum OutboxOpType {
  tasmeeRecord('tasmee_record'),
  attendanceMark('attendance_mark');

  const OutboxOpType(this.dbValue);

  final String dbValue;

  static OutboxOpType fromDb(String value) =>
      OutboxOpType.values.firstWhere((OutboxOpType t) => t.dbValue == value);
}

/// عملية كتابة مؤجّلة: تتسجّل محليًا فورًا وتتزامن مع السيرفر أول ما النت يرجع.
///
/// [id] مفتاح فريد (UUID) — وللتسميع هو نفسه الـ idempotency_key على السيرفر،
/// فإعادة الإرسال آمنة (السيرفر `on conflict do nothing`).
class OutboxOp {
  const OutboxOp({
    required this.id,
    required this.type,
    required this.payload,
    this.attempts = 0,
  });

  final String id;
  final OutboxOpType type;
  final Map<String, dynamic> payload;
  final int attempts;

  String get payloadJson => jsonEncode(payload);

  static Map<String, dynamic> decodePayload(String json) =>
      jsonDecode(json) as Map<String, dynamic>;
}
