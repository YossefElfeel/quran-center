import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// معالجة الصورة على الجهاز قبل الرفع: تصغير + علامة مائية + ضغط JPEG.
///
/// دالة نقية (مفيش I/O) عشان تتّختبر بسهولة. العلامة المائية بتُرسَم بخط نقطي
/// لاتيني من حزمة `image` (مش بتدعم العربي)، فبنستخدم اسم/تاريخ لاتيني كعلامة
/// حماية. علامة عربية محروقة في الصورة محتاجة رسم نص عبر Flutter ثم تركيب —
/// مؤجّلة. التصغير بيخلّي أطول بُعد = [maxDimension] بالكتير.
Uint8List watermarkAndCompressImage({
  required Uint8List bytes,
  required String watermark,
  int maxDimension = 1280,
  int quality = 80,
}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) {
    throw const FormatException('تعذّر قراءة الصورة');
  }

  img.Image out = decoded;
  if (out.width > maxDimension || out.height > maxDimension) {
    out = out.width >= out.height
        ? img.copyResize(out, width: maxDimension)
        : img.copyResize(out, height: maxDimension);
  }

  // شريط نص شبه شفّاف أسفل الصورة (خلفية غامقة + نص أبيض) عشان يبان على أي صورة.
  const int barHeight = 28;
  img.fillRect(
    out,
    x1: 0,
    y1: out.height - barHeight,
    x2: out.width,
    y2: out.height,
    color: img.ColorRgba8(0, 0, 0, 110),
  );
  img.drawString(
    out,
    watermark,
    font: img.arial24,
    x: 8,
    y: out.height - barHeight + 2,
    color: img.ColorRgba8(255, 255, 255, 230),
  );

  return Uint8List.fromList(img.encodeJpg(out, quality: quality));
}
