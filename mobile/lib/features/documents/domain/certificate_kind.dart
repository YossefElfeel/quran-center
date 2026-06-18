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

  String get labelAr => switch (this) {
    CertificateKind.juzAmma => 'إتمام جزء عمّ',
    CertificateKind.half => 'إتمام نصف القرآن',
    CertificateKind.full => 'إتمام القرآن الكريم',
    CertificateKind.honor => 'شهادة تفوّق',
  };

  static CertificateKind fromDb(String value) => switch (value) {
    'juz_amma' => CertificateKind.juzAmma,
    'half' => CertificateKind.half,
    'full' => CertificateKind.full,
    _ => CertificateKind.honor,
  };
}
