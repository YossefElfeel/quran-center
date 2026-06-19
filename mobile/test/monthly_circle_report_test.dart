import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/documents/domain/monthly_circle_report.dart';
import 'package:quran_center/features/documents/domain/monthly_circle_report_pdf.dart';

void main() {
  test('buildMonthlyCircleReportPdf بيطلّع PDF عربي صالح وغير فاضي', () async {
    final Uint8List ttf = File('assets/fonts/Cairo.ttf').readAsBytesSync();
    final Uint8List pdf = await buildMonthlyCircleReportPdf(
      report: const MonthlyCircleReport(
        circleName: 'حلقة النور',
        monthLabel: 'مايو ٢٠٢٦',
        activeStudents: 12,
        avgAttendanceRate: 0.85,
        passRate: 0.73,
        topStudentName: 'محمد أحمد',
        portions: <MonthlyCirclePortionProgress>[
          MonthlyCirclePortionProgress(label: 'جزء عمّ', passed: 9, total: 12),
          MonthlyCirclePortionProgress(
            label: 'سورة الملك',
            passed: 5,
            total: 8,
          ),
        ],
      ),
      fontData: ByteData.view(ttf.buffer),
    );
    expect(pdf.length, greaterThan(1000));
    expect(String.fromCharCodes(pdf.sublist(0, 4)), '%PDF');
  });

  test('buildMonthlyCircleReportPdf بيشتغل لما مفيش مقاطع', () async {
    final Uint8List ttf = File('assets/fonts/Cairo.ttf').readAsBytesSync();
    final Uint8List pdf = await buildMonthlyCircleReportPdf(
      report: const MonthlyCircleReport(
        circleName: 'حلقة فاضية',
        monthLabel: 'مايو ٢٠٢٦',
        activeStudents: 0,
        avgAttendanceRate: 0,
        passRate: 0,
        topStudentName: '',
        portions: <MonthlyCirclePortionProgress>[],
      ),
      fontData: ByteData.view(ttf.buffer),
    );
    expect(String.fromCharCodes(pdf.sublist(0, 4)), '%PDF');
    expect(pdf.length, greaterThan(1000));
  });
}
