import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// كشف حضور حلقة فاضي للطباعة (PDF عربي RTL) — دالة نقية بتاخد بايتس الخط.
Future<Uint8List> buildAttendanceSheetPdf({
  required String circleName,
  required String dateLabel,
  required List<String> studentNames,
  required ByteData fontData,
}) async {
  final pw.Font font = pw.Font.ttf(fontData);
  pw.Widget cell(String text, {bool header = false}) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: header ? 14 : 12,
        fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
  final pw.Document doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: <pw.Widget>[
            pw.Text(
              'كشف حضور — $circleName',
              style: pw.TextStyle(
                font: font,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(dateLabel, style: pw.TextStyle(font: font, fontSize: 12)),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey600),
              columnWidths: const <int, pw.TableColumnWidth>{
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(5),
                2: pw.FlexColumnWidth(2),
              },
              children: <pw.TableRow>[
                pw.TableRow(
                  children: <pw.Widget>[
                    cell('#', header: true),
                    cell('اسم الطالب', header: true),
                    cell('الحضور', header: true),
                  ],
                ),
                for (int i = 0; i < studentNames.length; i++)
                  pw.TableRow(
                    children: <pw.Widget>[
                      cell('${i + 1}'),
                      cell(studentNames[i]),
                      cell(''),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return doc.save();
}
