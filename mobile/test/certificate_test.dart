import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/documents/domain/certificate_eligibility.dart';
import 'package:quran_center/features/documents/domain/certificate_kind.dart';
import 'package:quran_center/features/documents/domain/certificate_pdf.dart';

void main() {
  group('أهلية الشهادة (zero-debt)', () {
    test('كل المقاطع passed → مؤهّل', () {
      expect(isDebtFreeForCertificate(<String>['passed', 'passed']), isTrue);
    });
    test('فيه مقطع لسه مش passed → مش مؤهّل', () {
      expect(
        isDebtFreeForCertificate(<String>['passed', 'failed_retry']),
        isFalse,
      );
    });
    test('مفيش مقاطع خالص → مش مؤهّل', () {
      expect(isDebtFreeForCertificate(<String>[]), isFalse);
    });
  });

  test('CertificateKind round-trip db ↔ enum', () {
    for (final CertificateKind k in CertificateKind.values) {
      expect(CertificateKind.fromDb(k.dbValue), k);
    }
  });

  test('buildCertificatePdf بيطلّع PDF عربي صالح وغير فاضي', () async {
    final Uint8List ttf = File('assets/fonts/Cairo.ttf').readAsBytesSync();
    final Uint8List pdf = await buildCertificatePdf(
      studentName: 'محمد أحمد',
      kindLabel: 'إتمام جزء عمّ',
      dateLabel: '١ يونيو ٢٠٢٦',
      fontData: ByteData.view(ttf.buffer),
    );
    expect(pdf.length, greaterThan(1000));
    expect(String.fromCharCodes(pdf.sublist(0, 4)), '%PDF');
  });
}
