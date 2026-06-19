import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:printing/printing.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../domain/certificate_pdf.dart';

/// معاينة/طباعة/مشاركة شهادة PDF عربية.
class CertificatePreviewScreen extends StatelessWidget {
  const CertificatePreviewScreen({
    required this.studentName,
    required this.kindLabel,
    required this.dateLabel,
    super.key,
  });

  final String studentName;
  final String kindLabel;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return AppScaffold(
      title: l.docCertificateTitle,
      body: PdfPreview(
        build: (_) async {
          final ByteData fontData = await rootBundle.load(
            'assets/fonts/Cairo.ttf',
          );
          final ByteData quranFontData = await rootBundle.load(
            'assets/fonts/Amiri-Regular.ttf',
          );
          final Uint8List bytes = await buildCertificatePdf(
            studentName: studentName,
            kindLabel: kindLabel,
            dateLabel: dateLabel,
            fontData: fontData,
            quranFontData: quranFontData,
          );
          return bytes;
        },
        canChangePageFormat: false,
        canChangeOrientation: false,
      ),
    );
  }
}
