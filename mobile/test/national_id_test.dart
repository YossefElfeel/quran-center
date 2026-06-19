import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/enrollment/domain/national_id.dart';

void main() {
  test('normalizeDigits بيحوّل العربي للغربي ويشيل غير الأرقام', () {
    expect(normalizeDigits('٢٩٨٠١٢٣٤٥-٦٧٨٩٠'), '29801234567890');
    expect(normalizeDigits('abc ١٢٣ xyz'), '123');
    expect(normalizeDigits('۲۹۸'), '298'); // فارسي
  });

  test('extractNationalId بيلاقي ١٤ رقم وسط نص', () {
    expect(
      extractNationalId('الرقم القومي ٢٩٨٠١٢٣٤٥٦٧٨٩٠ تمام'),
      '29801234567890',
    );
    expect(extractNationalId('ID: 29801234567890'), '29801234567890');
  });

  test('extractNationalId بيرجّع null لو مفيش ١٤ رقم', () {
    expect(extractNationalId('موبايل 0101234'), isNull);
    expect(extractNationalId('مفيش أرقام هنا'), isNull);
  });

  test('extractNationalId مابيلزقش أرقام من توكنز مفصولة', () {
    // ١١ + ٥ أرقام بمسافة — مفيش توكن طوله ١٤
    expect(extractNationalId('01012345678 12345'), isNull);
  });

  test('isValidNationalId', () {
    expect(isValidNationalId('29801234567890'), isTrue);
    expect(isValidNationalId('٢٩٨٠١٢٣٤٥٦٧٨٩٠'), isTrue);
    expect(isValidNationalId('123'), isFalse);
    expect(isValidNationalId('2980123456789'), isFalse); // ١٣ رقم
  });
}
