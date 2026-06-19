import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:quran_center/features/media/domain/image_watermark.dart';

void main() {
  Uint8List sampleJpeg(int w, int h) {
    final img.Image src = img.Image(width: w, height: h);
    img.fill(src, color: img.ColorRgb8(20, 120, 100));
    return Uint8List.fromList(img.encodeJpg(src, quality: 95));
  }

  test('watermarkAndCompressImage بيطلّع JPEG صالح ومصغّر', () {
    final Uint8List input = sampleJpeg(2000, 1500);
    final Uint8List out = watermarkAndCompressImage(
      bytes: input,
      watermark: 'QURAN CENTER 2026',
    );

    // رأس JPEG (FF D8) + قابل للفكّ + أطول بُعد <= 1280.
    expect(out.length, greaterThan(100));
    expect(out[0], 0xFF);
    expect(out[1], 0xD8);
    final img.Image? decoded = img.decodeImage(out);
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(1280));
    expect(decoded.height, lessThanOrEqualTo(1280));
  });

  test('watermarkAndCompressImage بيحافظ على الصور الصغيرة من غير تكبير', () {
    final Uint8List input = sampleJpeg(640, 480);
    final img.Image out = img.decodeImage(
      watermarkAndCompressImage(bytes: input, watermark: 'X'),
    )!;
    expect(out.width, 640);
    expect(out.height, 480);
  });

  test('watermarkAndCompressImage بيرمي على بايتس مش صورة', () {
    expect(
      () => watermarkAndCompressImage(
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        watermark: 'X',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
