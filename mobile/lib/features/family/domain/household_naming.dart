/// اسم الأسرة المقترح من اسم ولي الأمر: في التسمية المصرية اسم العيلة هو آخر
/// كلمة في الاسم ("محمد أحمد الشريف" → "الشريف"). بنضم "عبد" للكلمة اللي بعدها
/// عشان "أحمد عبد الله" تبقى "عبد الله" مش "الله". اسم من كلمة واحدة → فاضي
/// (مفيش اسم عيلة نعرفه).
String suggestedFamilyName(String guardianFullName) {
  final List<String> parts = guardianFullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((String p) => p.isNotEmpty)
      .toList();
  if (parts.length < 2) return '';
  final String last = parts.last;
  final String beforeLast = parts[parts.length - 2];
  if (parts.length >= 3 && (beforeLast == 'عبد' || beforeLast == 'أبو')) {
    return '$beforeLast $last';
  }
  return last;
}
