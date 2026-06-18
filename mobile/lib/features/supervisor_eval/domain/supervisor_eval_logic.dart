import 'dart:math';

/// اختيار عشوائي حتمي (بـ [seed]) لـ [count] عناصر من [items] بدون تكرار.
/// الـseed بيخلّي الاختيار قابل للاختبار؛ في التطبيق بيتمرّر seed متغيّر.
List<T> pickRandom<T>(List<T> items, int count, {required int seed}) {
  if (count <= 0 || items.isEmpty) return <T>[];
  final List<T> pool = List<T>.of(items);
  final Random rng = Random(seed);
  final int n = count < pool.length ? count : pool.length;
  final List<T> picked = <T>[];
  for (int i = 0; i < n; i++) {
    picked.add(pool.removeAt(rng.nextInt(pool.length)));
  }
  return picked;
}

/// متوسّط درجات (٠ لو فاضي) — يُستخدم لتجميع معايير التقييم.
double averageScore(Iterable<int> scores) {
  final List<int> list = scores.toList();
  if (list.isEmpty) return 0;
  return list.reduce((int a, int b) => a + b) / list.length;
}
