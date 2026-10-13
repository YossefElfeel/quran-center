import '../../../core/logging/logger.dart';

/// نوع الشهادة.
enum CertificateKind {
  juzAmma,
  half,
  full,
  honor;

  String get dbValue => switch (this) {
    CertificateKind.juzAmma => 'juz_amma',
    CertificateKind.half => 'half',
    CertificateKind.full => 'full',
    CertificateKind.honor => 'honor',
  };

  static CertificateKind fromDb(String value) {
    switch (value) {
      case 'juz_amma':
        return CertificateKind.juzAmma;
      case 'half':
        return CertificateKind.half;
      case 'full':
        return CertificateKind.full;
      case 'honor':
        return CertificateKind.honor;
    }
    AppLog.warn('Unknown certificate kind from server: $value');
    return CertificateKind.honor;
  }
}
