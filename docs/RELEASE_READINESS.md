# جاهزية الإطلاق (Release Readiness)

> الحالة: نواة المنصة (Phases 0–14) + MILESTONE 1 (مكاسب سريعة) مبنية ومتحقّق
> منها (analyze نضيف، اختبارات خضراء، smoke tests لكل migration، RLS متحقّق
> structurally + بمحاكاة دخول). الملف ده بيوثّق اللي **لسه محتاج خطوات يدوية/
> خارجية** أو مؤجّل قبل الإطلاق.

> **تحديث M8 (2026-06-19):**
> - **M8.3 i18n** — كل نصوص التطبيق اتنقلت لمفاتيح `AppL10n` (تطبيق عربي، الحدّ
>   المتروك عربي عمدًا: `labelAr` في الدومين + رسايل `core/error` + الأرقام).
> - **M8.1 أوفلاين** — طابور كتابة (Drift outbox) للحضور/التسميع بـ idempotency +
>   كاش الحصة؛ الحصة تتحمّل قطع النت وتفتح أوفلاين بعد إعادة التشغيل.
> - **M8.2 جودة/CI** — الـ CI بيشتغل على dev، + lane للويب العام، + **وظيفة Supabase
>   بتشغّل عزل RLS + اختبار تدفّق المحرّك (integration) على stack محلي**، + goldens
>   بتتولّد على Linux. الـ ٤+١ jobs خضرا.
> - **إصلاح drift في الـ migrations**: التشغيل النضيف (fresh `supabase db reset`)
>   كشف ٣ حاجات على الهوستد مش متسجّلة كـ migrations — اتضافوا فبقت الـ migrations
>   بتعيد إنتاج السكيمة من الصفر: `rls_auto_enable` (event trigger)، تفعيل
>   `pg_cron`، ومنح الجداول لأدوار الـ API (`authenticated`/`anon`/`service_role`).

> **تحديث M6 + M9 (2026-06-19):**
> - **M6 لوحة السوبر أدمن** (D0–D4، CI أخضر): بوابة super_admin + shell · إعدادات
>   النظام · مستخدمون/أدوار + دعوة · audit (+CSV) · اشتراكات · شكاوى · تحليلات
>   (recharts) · كورسات/مسابقات · PDPL · **تقمّص الدور مدقّق (read-only + time-box)**.
> - **M9 تجهيز الإطلاق**: توقيع release من `key.properties` + R8/ProGuard + دليل
>   `docs/RELEASE_ANDROID.md`. **الـ AAB الموقّع + الرفع لـ Play = إجراؤك** (keystore
>   + حساب Play). جرّب `--release` على جهاز قبل الرفع (R8 مفعّل).
>
> **بنود مؤجّلة عمدًا / إجراؤك (مش أخطاء):**
> - `invite-user`: الكود اتصلّح (كان بايظ بعد M2.3) — **محتاج إعادة نشر** (`supabase
>   functions deploy invite-user`) عشان الدعوة تشتغل.
> - `upload-media` (علامة مائية للفيديو): مؤجّلة — Deno edge مافيهوش ffmpeg.
> - تقمّص الدور بالـ JWT الكامل (act claim على مستوى RLS): مؤجّل لمراجعة أمنية؛
>   المتاح حاليًا معاينة قراءة-فقط مدقّقة.
> - نشر اللوحة + الويب على Vercel، وتفعيل leaked-password (Pro): إجراؤك.

---

## 1) أمان

### (أ) تدوير المفتاح السري المكشوف — ✅ **اتعمل (2026-06-18)**
المفتاح (`sb_secret_…`) القديم المكشوف اتدوّر (المستخدم عمل Revoke + توليد جديد).
مفيش أي Edge Function اتنشرت بالمفتاح القديم ومفيش حسابات اتعملت بيه. النشر بقى
مفتوح — بس نشر الدوال/إنشاء أول حساب حقيقي بيتعمل **بتأكيد صريح من المستخدم**.

### (ب) حماية الباسوردات المسرّبة (advisor: auth_leaked_password_protection) — مؤجّل (Pro)
الميزة دي متاحة على باقة **Pro** بس؛ المشروع حاليًا على الباقة المجانية فالتوگل
مش متاح. مؤجّلة للإطلاق (الترقية لـ Pro قبل المستخدمين الحقيقيين). الـ advisor
هيفضل يطلّع WARN على المجاني — **متوقّع ومش بلوكر**.

### (ج) advisor 0029 — نقل دوال RLS المساعدة لـ private — ✅ اتعمل (2026-06-18)
> اتنفّذ: الـ١٦ helper اتنقلوا لـ `private` بـ `ALTER FUNCTION ... SET SCHEMA` (الـ OID
> محفوظ → السياسات شغّالة من غير إعادة كتابة). متحقّق بـ `supabase/tests/rls_isolation.sql`
> ("RLS OK") + advisors (0029 بقى مقصور على RPCs شرعية بيندهها التطبيق:
> `eligible_certificate_students, teacher_pass_rate, log_media_access,
> set_person_national_id, enroll_student`). الخطة الأصلية للمرجع:
دوال الـ SECURITY DEFINER المساعدة في `public` فبتظهر كـ RPC للـ `authenticated`
(تسريب بسيط: بوليانات عن المستخدم الحالي/علاقاته). الإصلاح المخطّط (محتاج اختبارات
integration/RLS كاملة شغّالة قبل التطبيق عشان مايكسرش الـ RLS):

- أنشئ schema `private` (مش مكشوف عبر PostgREST).
- **انقل لـ private** الدوال اللي تُستخدم **جوّا السياسات بس**:
  `current_person_id, has_role, is_admin, is_super_admin, is_supervisor,
  is_teacher, is_parent, is_guardian_of, is_guardian_of_enrollment,
  teaches_circle, teaches_enrollment, is_competition_judge,
  is_parent_of_teachers_student, has_active_media_consent, media_consent_ok,
  is_certificate_eligible, household_has_active_subscription,
  person_has_active_subscription`.
  وحدّث **كل** السياسات اللي بتشير لها لـ `private.fn(...)` + `grant execute`
  للـ authenticated على نسخ private.
- **تفضل في public** (لأن التطبيق بينده عليها كـ RPC):
  `record_tasmee, my_subscription_active, households_with_status,
  circle_pass_rates, teacher_pass_rate, log_media_access, eligible_certificate_students`.
- ✅ `rls_auto_enable` **اتقفل خلاص** (migration `20260618240001`): اتسحبت صلاحية
  التنفيذ من anon/authenticated/public. هو event-trigger مش بيتنده من أي سياسة،
  فمحتاجش نقل لـ private.
- بعد التطبيق: شغّل smoke الـ RLS + اختبارات وصول سلبية للتأكد إن العزل لسه شغّال.

> ملاحظة: دي WARN مش error، والتسريب محدود؛ اتأجّلت عمدًا عشان إعادة كتابة ~40
> سياسة بدون integration suite شغّال خطر على طبقة الأمان كلها (مرتبط بـ M8.2).

### (د) حضانة مفتاح الرقم القومي (PDPL) — ✅ المفتاح في Vault (2026-06-18)
`national_id_hmac` (HMAC blind index) + `national_id_encrypted` شغّالين عبر
`set_person_national_id`، والـ pepper (٣٢ بايت عشوائي) متخزّن في Supabase Vault
(مش في الكود) — **M2.4 اتقفل**. **فاضل (بشري):** استشارة PDPL قانونية + توثيق
دورة تدوير المفتاح قبل جمع بيانات حقيقية.

---

## 2) Edge Functions
- ✅ **`invite-user`** — منشورة (ACTIVE, verify_jwt, 2026-06-18). دعوة أدمن →
  auth user + person + role. فاضل: **شاشة الدعوة في التطبيق** (M3 UI) + أول دعوة
  حقيقية بإيد الأدمن.
- ✅ **`submit-public-application`** — منشورة (ACTIVE, verify_jwt). تقديم المسابقة
  العام (consent + dedupe موبايل). فاضل: rate-limit/OTP + الصفحة العامة (M7).
- ⏸️ **`upload-media`** — مؤجّلة: العلامة المائية/ضغط الفيديو سيرفر-سايد مش عملي في
  Deno Edge (مفيش ffmpeg). يتحسم (علامة صور بس / خدمة ترميز / overlay كلاينت) قبل
  تفعيل رفع الفيديو. معرض الوسائط (Phase 7a) متوقّف عليها.

## 3) Cron (pg_cron) — ✅ مفعّل (1.6.4)
**اتعمل واتحقّق منه (DB smoke):**
- ✅ **تصعيد الشكاوى ٤٨س** — `escalate_overdue_complaints()` (كل ساعة، `0 * * * *`).
  إشعار للمديرين (admin/super_admin) لمّا شكوى open/reopened تعدّي 48h بدون رد؛
  idempotent عبر `complaint.escalated_at`. (`20260618240002`)
- ✅ **تنبيه الاشتراك المتأخّر** — `notify_overdue_subscriptions()` (يوميًا 06:00
  UTC). إشعار لأولياء الأمور مرة لكل (أسرة، شهر) بعد فترة السماح؛ idempotent عبر
  `subscription_overdue_notice`. (`20260618240003`)

**مؤجّل بأسبابه:**
- **قفل الشهر** (مسوّدات تقييم + تقرير حلقة + بطاقات تقدّم + تدوير اشتراك +
  auto_finalize للـ missed) — تقيل ومرتبط بتوليد تقارير الشهر؛ يتعمل كجهد مركّز.
- **حذف TTL لتسجيلات العامة** — `public_registration` لسه ناقص أعمدة TTL/status
  (يتعمل مع M7 الصفحة العامة).
- **احتفاظ الوسائط** (سيب أول + آخر فيديو) — مرتبط بتخزين الوسائط/الـ Edge (M3).
- **ترشيح مرشّحي الشهادة** — مؤجّل لبعد M5 (خرائط الأجزاء) عشان نرشّح إتمام جزء
  فعلي بدل أي طالب صفر-دَيْن (تجنّب ضوضاء).

## 4) الإطلاق (Android) — يدوي/خارجي
- توقيع التطبيق (keystore) + R8/ProGuard + أيقونة + بيان متجر عربي.
- `flutter build appbundle --flavor prod` → Google Play internal testing → إطلاق.
- الصفحة العامة (المسابقة + الكورسات): **تطبيق Next.js منفصل `web/`** (React) —
  اتبنى ومتحقّق (`/courses` anon + `/competition` بنموذج بينده submit-public-application).
  فاضل: **نشر على Vercel** (بإذن المستخدم) + rate-limit/OTP على الـ Edge قبل الإنتاج.

## 5) لوحة السوبر أدمن (Track D — Next.js) — لسه ما اتبنتش
D0 scaffolding اتعمل بس. D1–D4 (إدارة مستخدمين/إعدادات، تدقيق، تحليلات،
تقمّص الدور) مسار متوازي منفصل (M6).

---

## 6) UI / شغل مؤجّل (الـ backend جاهز)
- **معرض الوسائط (Phase 7a)** — محتاج `upload-media` + signed URLs منشورين (M3).
- **شاشة دعوة المستخدمين (Phase 7b)** — محتاجة `invite-user` منشورة (M3).
- **تراكم الرحلة التلقائي** عند النجاح/النقل — M5 (مع خرائط الأجزاء/الصفحات).
- **تحسينات المسابقة (Phase 12)** — محرّر الفئات/الجولات، تضمين يوتيوب في التحكيم،
  إدخال per-criterion.
- **الصفحة العامة (Flutter Web) + TTL cron (Phase 13)** — M7.

> اتعمل بالفعل (MILESTONE 1): لوحة الشرف + التقييم الشهري (M1.3/M1.4)، إصدار
> الشهادة + تقارير PDF (M1.5/M1.9)، محرّر ملف المعلّم (M1.8)، عارض تقييمات
> المحفّظ + الإخفاء (M1.7)، قبول/رفض متقدّمي المسابقة (M1.6)، تصعيد الشكاوى ٤٨س (M4).

---

## 7) اللي متحقّق منه فعلاً
- **عزل RLS** (مصفوفة): ولي الأمر يشوف بيانات ابنه بس؛ المعلّم يشوف طلبة حلقته
  بس (smoke: `g1_certs=1, g1_sees_s2=0, t1_certs=1`).
- **بوابات الاعتماد سيرفر-سايد**: التقييم الشهري + تطوّر المعلّم (المشرف بس)،
  أهلية الشهادة (zero-debt)، موافقة وسائط البنت (قراءة+كتابة)، المعلّم أعمى عن
  تقييمه، الشكوى للمدير بس.
- **سياسة الأنيميشن**: مفيش `.repeat(` في الكود (حارس CI).
- **CI**: `flutter analyze` نضيف + `dart format` + الاختبارات خضراء (96) + build_runner.
- **advisors**: مفيش جدول من غير RLS؛ `rls_auto_enable` (0028 anon) اتقفل؛
  الـ helpers اتنقلت لـ `private` (0029 بقى على RPCs شرعية بس) +
  leaked-pw (محتاج تأكيد) + INFO واحد (`subscription_overdue_notice` RLS-no-policy،
  مقصود لجدول نظام). الكرونات الجداد مش مكشوفة كـ RPC (execute مسحوب).
