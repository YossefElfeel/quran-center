# إطلاق أندرويد (M9) — الخطوات اليدوية

> الكود جاهز للإصدار: توقيع release من `key.properties` (مع fallback للـ debug)،
> R8/ProGuard مفعّل، وقواعد ProGuard للـ plugins (ML Kit / sqlite). الخطوات دي
> لازم تتعمل **يدويًا** لأنها محتاجة keystore + حساب Google Play (إجراؤك).

## 1) إنشاء الـ keystore (مرة واحدة)
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
احفظه **برّه الريبو** (أو في `mobile/android/app/` — هو git-ignored). متضيّعوش.

## 2) إعداد التوقيع
انسخ `mobile/android/key.properties.example` لـ `mobile/android/key.properties`
واملا: `storePassword` / `keyPassword` / `keyAlias` / `storeFile` (مسار الـ jks).
الملف ده **git-ignored** — عمره ما يتكوميت.

## 3) ضبط الأيقونة والإصدار
- الأيقونة: استبدل أيقونات `mipmap-*` (أو استخدم `flutter_launcher_icons`).
- رقم الإصدار: `version: 1.0.0+1` في `pubspec.yaml` (الـ `+N` هو versionCode).

## 4) بناء الـ AAB الموقّع
```bash
cd mobile
flutter build appbundle --release --dart-define-from-file=env/prod.json
```
الناتج: `build/app/outputs/bundle/release/app-release.aab`.

> **مهم:** R8 مفعّل (`isMinifyEnabled = true`). **جرّب الـ release على جهاز فعلي**
> (`flutter run --release`) قبل الرفع — للتأكد إن ProGuard ما شالش حاجة (خصوصًا
> ML Kit OCR). لو ظهرت مشكلة، زوّد `-keep` في `android/app/proguard-rules.pro`.

## 5) الرفع لـ Google Play
- Play Console → إنشاء التطبيق → Internal testing.
- ارفع الـ `.aab`، املا بيان المتجر العربي (الوصف/الصور/سياسة الخصوصية — PDPL).
- بعد اختبار داخلي → Production.

## ملاحظات أمان
- الـ `key.properties` والـ `*.jks`/`*.keystore` كلها git-ignored (شوف `.gitignore`).
- من غير `key.properties`، الـ release بيوقّع بالـ debug (للبناء المحلي بس — **مش**
  صالح للرفع على Play).
