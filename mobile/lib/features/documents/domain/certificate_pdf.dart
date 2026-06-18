import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// يبني شهادة PDF عربية RTL (دالة نقية — بتاخد بايتس الخط، بترجّع Uint8List).
/// قابلة للاختبار من غير Flutter (الخط بيتمرّر، مش بيتقري من rootBundle).
Future<Uint8List> buildCertificatePdf({
  required String studentName,
  required String kindLabel,
  required String dateLabel,
  required ByteData fontData,
  String centerName = 'دار تحفيظ القرآن الكريم',
}) async {
  final pw.Font font = pw.Font.ttf(fontData);
  final pw.Document doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (pw.Context context) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.teal700, width: 4),
          ),
          padding: const pw.EdgeInsets.all(36),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: <pw.Widget>[
              pw.Text(
                centerName,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 18,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                'شهادة',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 44,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal700,
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                'تشهد الدار بأن الطالب',
                style: pw.TextStyle(font: font, fontSize: 20),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                studentName,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'قد أتمّ بنجاح: $kindLabel',
                style: pw.TextStyle(font: font, fontSize: 22),
              ),
              pw.SizedBox(height: 28),
              pw.Text(
                dateLabel,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 16,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return doc.save();
}
