import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/arabic_numerals.dart';
import 'monthly_circle_report.dart';

/// تقرير الحلقة الشهري (PDF عربي RTL) — دالة نقية بتاخد البيانات وبايتس الخط.
Future<Uint8List> buildMonthlyCircleReportPdf({
  required MonthlyCircleReport report,
  required ByteData fontData,
}) async {
  final pw.Font font = pw.Font.ttf(fontData);

  String pct(double rate) =>
      '${toArabicDigits((rate * 100).round().toString())}٪';

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
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: <pw.Widget>[
              pw.Center(
                child: pw.Text(
                  'تقرير الحلقة الشهري',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal700,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  '${report.circleName} — ${report.monthLabel}',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
              ),
              pw.SizedBox(height: 20),
              row('عدد الطلبة النشطين', arabicNumber(report.activeStudents)),
              row('متوسّط الحضور', pct(report.avgAttendanceRate)),
              row('نسبة النجاح', pct(report.passRate)),
              row(
                'المتفوّق',
                report.topStudentName.isEmpty ? '—' : report.topStudentName,
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'تقدّم المقاطع',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              if (report.portions.isEmpty)
                pw.Text(
                  'لا يوجد تسميع مسجّل للشهر.',
                  style: pw.TextStyle(font: font, fontSize: 12),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey600),
                  columnWidths: const <int, pw.TableColumnWidth>{
                    0: pw.FlexColumnWidth(5),
                    1: pw.FlexColumnWidth(2),
                    2: pw.FlexColumnWidth(2),
                    3: pw.FlexColumnWidth(2),
                  },
                  children: <pw.TableRow>[
                    pw.TableRow(
                      children: <pw.Widget>[
                        cell('المقطع', header: true),
                        cell('نجَح', header: true),
                        cell('الإجمالي', header: true),
                        cell('النسبة', header: true),
                      ],
                    ),
                    for (final MonthlyCirclePortionProgress p
                        in report.portions)
                      pw.TableRow(
                        children: <pw.Widget>[
                          cell(p.label),
                          cell(arabicNumber(p.passed)),
                          cell(arabicNumber(p.total)),
                          cell(p.total == 0 ? '—' : pct(p.passed / p.total)),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
  return doc.save();
}
