# منصة مركز تحفيظ القرآن — Quran Center Platform

منصة لإدارة دار/مركز تحفيظ قرآن في مصر (موبايل-أول، عربي مصري، RTL). الـ backend واحد مشترك على **Supabase**، وفيه ٣ واجهات.

## بنية الريبو (monorepo)

```
quran/
├─ mobile/      # تطبيق Flutter (Android الأول ثم iOS) + هدف Flutter Web للصفحة العامة/الكورسات
├─ dashboard/   # لوحة السوبر أدمن — Next.js (تتنشر على Vercel)
└─ supabase/    # migrations + RLS + Edge Functions + seed — مشترك (مصدر الحقيقة للـ schema)
```

> الخطة الكاملة (القرارات + نموذج البيانات + المحرّك + الصلاحيات + المراحل): `C:\Users\yosse\.claude\plans\we-will-work-on-moonlit-rabin.md`

## المتطلبات (Toolchain)

| الأداة | الإصدار المتحقّق منه |
|---|---|
| Flutter | 3.44+ (Dart 3.12+) |
| Node | 20+ (للـ dashboard) |
| Supabase CLI | اختياري محليًا (نستخدم Supabase المُدار) |
| Git | أي إصدار حديث |

## التشغيل

### الموبايل (`mobile/`)
```bash
cd mobile
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart   # أو main.dart
flutter analyze
flutter test
```

### لوحة السوبر أدمن (`dashboard/`)
```bash
cd dashboard
pnpm install
pnpm dev
```

### الـ backend (`supabase/`)
الـ migrations والـ seed و Edge Functions. التطبيق على مشروع Supabase مُدار (RLS طبقة الصلاحيات).

## مبادئ هندسية ملزمة
1. **مكوّنات صغيرة** — مفيش صفحة في ملف واحد ضخم (Flutter widgets / React components صغيرة).
2. **مفيش animation بيلفّ على طول** — implicit/one-shot بس، واحترام reduced-motion.
3. كل تصاريح الوصول في **RLS** (مش UI بس).
4. `service-role` لـ Supabase في **server-side** بس (لوحة الويب) — عمره ما يلمس المتصفح.
