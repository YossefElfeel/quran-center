# خطة التحقق الشاملة (Verification Plan)

> قائمة تحقّق تنفيذية لكل ما اتبنى — كل بند له **أمر** و**نتيجة متوقّعة** و**نتيجة
> فعلية**. شغّل من جذر الريبو إلا لو محدّد غير كده.
>
> **آخر تشغيل: 2026-06-19 — كل البنود نجحت ✅ (مفيش أخطاء).**

## A) الموبايل (Flutter — `mobile/`)

| # | البند | الأمر | متوقّع | فعلي |
|---|---|---|---|---|
| A1 | تحليل ساكن | `flutter analyze` | No issues | ✅ No issues found |
| A2 | الاختبارات (بوابة) | `flutter test --exclude-tags golden` | كلها تنجح | ✅ **117 passed** |
| A3 | تنسيق الكود | `dart format --output=none --set-exit-if-changed lib test` | exit 0 | ✅ exit 0 (نضيف) |
| A4 | حارس الأنيميشن | `grep -rn --include=*.dart '\.repeat(' lib` | لا نتائج | ✅ لا `.repeat` |
| A5 | الأوفلاين (outbox) | `flutter test test/outbox_processor_test.dart` | تنجح | ✅ 8 passed |
| A6 | كاش الحصة | `flutter test test/session_cache_test.dart` | تنجح | ✅ 2 passed |
| A7 | شهادة Amiri (PDF) | `flutter test test/certificate_test.dart` | تنجح | ✅ 6 passed (آية Amiri) |
| A8 | i18n — مفيش نص UI متبقّي | scan على `*/presentation` | 0 | ✅ 0 hits |
| A9 | golden RTL | على Linux في CI | يتقارن أخضر | ✅ Goldens job أخضر |

## B) لوحة السوبر أدمن (`dashboard/`)

| # | البند | الأمر | متوقّع | فعلي |
|---|---|---|---|---|
| B1 | Lint | `pnpm exec eslint` | exit 0 | ✅ exit 0 |
| B2 | Build | `pnpm exec next build` | success | ✅ success (12 routes) |

## C) الويب العام (`web/`)

| # | البند | الأمر | متوقّع | فعلي |
|---|---|---|---|---|
| C1 | Lint + build | CI lane | أخضر | ✅ Public Web أخضر |

## D) قاعدة البيانات (Supabase)

| # | البند | الأمر | متوقّع | فعلي |
|---|---|---|---|---|
| D1 | عزل RLS | `supabase/tests/rls_isolation.sql` (MCP) | "RLS OK" | ✅ RLS OK (rolled back) |
| D2 | تدفّق المحرّك | `supabase/tests/engine_flow.sql` (MCP) | "ENGINE OK" | ✅ ENGINE OK (rolled back) |
| D3 | advisors الأمان | MCP `get_advisors` | baseline | ✅ 1 INFO + 5 RPC + leaked-pw (مفيش جديد) |
| D4 | self-containedness | `supabase db reset` نضيف في CI | بتتطبّق كلها | ✅ Supabase job أخضر |

## E) التكامل المستمر (CI)

| # | البند | متوقّع | فعلي |
|---|---|---|---|
| E1 | آخر تشغيل على `dev` | ٥ jobs خضرا | ✅ success (mobile · web · dashboard · supabase · goldens) |

## F) الحالة العامة

| # | البند | متوقّع | فعلي |
|---|---|---|---|
| F1 | شجرة Git | نظيفة، مدفوع | ✅ CLEAN |
| F2 | M9 توقيع | secrets git-ignored + fallback للـ debug | ✅ key.properties/*.jks مُتجاهَلة + fallback موجود |

---

## بنود إجراؤك (مش أخطاء — موثّقة في `RELEASE_READINESS.md` / `RELEASE_ANDROID.md`)
- **إعادة نشر `invite-user`**: `supabase functions deploy invite-user` (اتصلّح باج post-M2.3).
- **توقيع AAB + رفع Play**: keystore + حساب Play (دليل `RELEASE_ANDROID.md`)؛ جرّب `--release` على جهاز.
- **نشر Vercel** للّوحة + الويب.
- **مؤجّل لقرار:** `upload-media` (ffmpeg) · تقمّص JWT الكامل (مراجعة أمنية) · leaked-password (Pro).

**رمز:** ✅ نجح · ⚙️ إجراء يدوي.
