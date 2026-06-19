import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/documents/domain/attendance_sheet_pdf.dart';
import 'package:quran_center/features/documents/domain/progress_card_pdf.dart';

void main() {
  late Uint8List ttf;
  setUpAll(() {
    ttf = File('assets/fonts/Cairo.ttf').readAsBytesSync();
  });

  test('buildProgressCardPdf بيطلّع PDF صالح', () async {
    final Uint8List pdf = await buildProgressCardPdf(
      studentName: 'محمد أحمد',
      circleName: 'حلقة الفجر',
      present: 10,
      absent: 1,
      excused: 0,
      late: 2,
      latestScore: '٨/١٠',
      fontData: ByteData.view(ttf.buffer),
    );
    expect(pdf.length, greaterThan(1000));
    expect(String.fromCharCodes(pdf.sublist(0, 4)), '%PDF');
  });

  test('buildAttendanceSheetPdf بيطلّع PDF صالح', () async {
    final Uint8List pdf = await buildAttendanceSheetPdf(
      circleName: 'حلقة الفجر',
      dateLabel: '١ يونيو ٢٠٢٦',
      studentNames: <String>['محمد', 'أحمد', 'سارة'],
      fontData: ByteData.view(ttf.buffer),
    );
    expect(pdf.length, greaterThan(1000));
    expect(String.fromCharCodes(pdf.sublist(0, 4)), '%PDF');
  });
}
