import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/national_id.dart';

/// مسح الرقم القومي بالكاميرا (OCR على الجهاز). بيرجّع الرقم المستخرَج (١٤ رقم)
/// عبر Navigator.pop، أو null لو اتقفل. مفيش تخزين للصورة بعد القراءة.
/// ملاحظة: نموذج ML Kit on-device لاتيني، فالأرقام العربية-الهندية ممكن متتقريش
/// بدقّة دايمًا — الإدخال اليدوي متاح كبديل.
class NationalIdScanSheet extends StatefulWidget {
  const NationalIdScanSheet({super.key});

  @override
  State<NationalIdScanSheet> createState() => _NationalIdScanSheetState();
}

class _NationalIdScanSheetState extends State<NationalIdScanSheet> {
  bool _busy = false;
  String? _result;
  String? _error;

  Future<void> _scan() async {
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    TextRecognizer? recognizer;
    try {
      final XFile? shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
      );
      if (shot == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognized = await recognizer.processImage(
        InputImage.fromFilePath(shot.path),
      );
      final String? id = extractNationalId(recognized.text);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = id;
        _error = id == null
            ? 'مش لاقيين الرقم في الصورة — صوّر تاني أو اكتبه يدوي'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'مش قادرين نقرا الصورة — اكتب الرقم يدوي';
      });
    } finally {
      await recognizer?.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'مسح الرقم القومي',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_result != null) ...<Widget>[
            Text(
              toArabicDigits(_result!),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'استخدم الرقم ده',
              icon: Icons.check,
              onPressed: () => Navigator.of(context).pop(_result),
            ),
            TextButton(onPressed: _scan, child: const Text('صوّر تاني')),
          ] else ...<Widget>[
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            AppButton(
              label: 'صوّر البطاقة',
              icon: Icons.camera_alt,
              onPressed: _scan,
            ),
          ],
        ],
      ),
    );
  }
}
