// أداة تطوير: تولّد شهادة عيّنة (PDF) للمعاينة البصرية لخط Amiri/التشكيل.
// تشغيل: من مجلد mobile/ → `dart run tool/gen_sample_certificate.dart`
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';

import 'package:quran_center/features/documents/domain/certificate_pdf.dart';

Future<void> main() async {
  final Uint8List cairo = File('assets/fonts/Cairo.ttf').readAsBytesSync();
  final Uint8List amiri = File(
    'assets/fonts/Amiri-Regular.ttf',
  ).readAsBytesSync();
  final Uint8List pdf = await buildCertificatePdf(
    studentName: 'محمد أحمد عبد الله',
    kindLabel: 'إتمام حفظ جزء عمّ',
    dateLabel: '١٩ يونيو ٢٠٢٦',
    fontData: ByteData.view(cairo.buffer),
    quranFontData: ByteData.view(amiri.buffer),
  );
  final File out = File('sample_certificate.pdf');
  out.writeAsBytesSync(pdf);
  print('wrote ${out.path} (${pdf.length} bytes)');
}
