import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// بطاقة تقدّم الطالب (PDF عربي RTL) — دالة نقية بتاخد بايتس الخط.
Future<Uint8List> buildProgressCardPdf({
  required String studentName,
  required String circleName,
  required int present,
  required int absent,
  required int excused,
  required int late,
  required ByteData fontData,
  String? latestScore,
}) async {
  final pw.Font font = pw.Font.ttf(fontData);
  pw.Widget row(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 16)),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
  final pw.Document doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: <pw.Widget>[
              pw.Center(
                child: pw.Text(
                  'بطاقة تقدّم الطالب',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal700,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              row('الطالب', studentName),
              row('الحلقة', circleName),
              if (latestScore != null) row('آخر تسميع', latestScore),
              pw.Divider(),
              row('حاضر', present.toString()),
              row('غايب', absent.toString()),
              row('بعذر', excused.toString()),
              row('متأخّر', late.toString()),
            ],
          ),
        ),
      ),
    ),
  );
  return doc.save();
}
