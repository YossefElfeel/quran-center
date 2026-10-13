import 'package:flutter/material.dart';

abstract final class AppIcons {
  static const IconData absent = Icons.person_off;
  static const IconData present = Icons.check_circle;
  static const IconData excused = Icons.event_busy;
  static const IconData tasmee = Icons.record_voice_over;
  static const IconData note = Icons.note_add_outlined;
  static const IconData drillIn = Icons.chevron_right;

  /// كلمة السر / الأمان (صف "تغيير كلمة السر" في الإعدادات).
  static const IconData lock = Icons.lock_outline;

  /// حصة النهارده لسه ماتفتحتش (محايد/منتظر — مش "خلصت").
  static const IconData sessionPending = Icons.event_note;

  /// حصة النهارده اتقفلت.
  static const IconData sessionClosed = Icons.event_available;

  /// محتوى مقفول لحد تجديد الاشتراك.
  static const IconData locked = Icons.lock_outline;

  /// قرار رفض (عذر/طلب مسابقة) — مقابل [approved].
  static const IconData rejected = Icons.cancel;
  static const IconData approved = Icons.check_circle;
}
