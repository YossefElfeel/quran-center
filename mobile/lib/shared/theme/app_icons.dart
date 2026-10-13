import 'package:flutter/material.dart';

abstract final class AppIcons {
  static const IconData absent = Icons.person_off;
  static const IconData present = Icons.check_circle;
  static const IconData excused = Icons.event_busy;
  static const IconData tasmee = Icons.record_voice_over;
  static const IconData note = Icons.note_add_outlined;
  static const IconData drillIn = Icons.chevron_right;

  /// قرار رفض (عذر/طلب مسابقة) — مقابل [approved].
  static const IconData rejected = Icons.cancel;
  static const IconData approved = Icons.check_circle;
}
