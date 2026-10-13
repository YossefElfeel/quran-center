import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../domain/session_write_block.dart';

/// رسالة سبب إيقاف تسجيل الحصص للمستخدم.
extension SessionWriteBlockLabel on SessionWriteBlock {
  String label(AppL10n l) => switch (this) {
    SessionWriteBlock.freezeSessions => l.sesWritesFrozen,
    SessionWriteBlock.maintenanceMode => l.sesWritesMaintenance,
  };
}
