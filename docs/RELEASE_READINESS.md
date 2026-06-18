# جاهزية الإطلاق (Release Readiness)

> الحالة: نواة المنصة (Phases 0–14) + MILESTONE 1 (مكاسب سريعة) مبنية ومتحقّق
> منها (analyze نضيف، اختبارات خضراء، smoke tests لكل migration، RLS متحقّق
> structurally + بمحاكاة دخول). الملف ده بيوثّق اللي **لسه محتاج خطوات يدوية/
> خارجية** أو مؤجّل قبل الإطلاق.

---

## 1) أمان

### (أ) تدوير المفتاح السري المكشوف — ✅ **اتعمل (2026-06-18)**
المفتاح (`sb_secret_…`) القديم المكشوف اتدوّر (المستخدم عمل Revoke + توليد جديد).
مفيش أي Edge Function اتنشرت بالمفتاح القديم ومفيش حسابات اتعملت بيه. النشر بقى
مفتوح — بس نشر الدوال/إنشاء أول حساب حقيقي بيتعمل **بتأكيد صريح من المستخدم**.

### (ب) حماية الباسوردات المسرّبة (advisor: auth_leaked_password_protection) — ⚠️ **تأكيد مطلوب**
المستخدم فعّلها (Authentication → Attack Protection → "Prevent use of leaked
passwords"). **بس** الـ security advisor لسه بيرجّعها `disabled` بعد فحصين على مدى
دقايق. محتاج تأكيد إن التوگل اتحفظ فعلًا (مش رمادي/محتاج باقة Pro). لو فضل WARN
بعد فترة، يتراجع التفعيل.

### (ج) advisor 0029 — نقل دوال RLS المساعدة لـ schema خاص — مؤجّل (test-gated)
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

### (د) حضانة مفتاح الرقم القومي (PDPL)
`national_id_hmac` (blind index) + `national_id_encrypted`. المفاتيح تتحط في
Supabase Vault (مش في الكود)، وتتوثّق سياسة تدوير. استشارة قانونية PDPL قبل
جمع بيانات حقيقية.

---

## 2) Edge Functions للنشر (source جاهز، النشر بتأكيد المستخدم)
المفتاح اتدوّر (1-أ) فالنشر مفتوح. بعد ضبط الـ secrets (`supabase secrets set ...`):
- `invite-user` — دعوة مستخدم (أدمن) → بيعمل auth user + person + role. **حسّاس
  (auth): النشر/أول دعوة حقيقية بتأكيد المستخدم.**
- `upload-media` — رفع وسائط بفحص الموافقة. **TODO قبل الإنتاج: علامة مائية +
  ضغط فيديو سيرفر-سايد.**
- `submit-public-application` — تقديم عام للمسابقة (consent + dedupe موبايل).
- نشر: `supabase functions deploy <name>`.

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
- الصفحة العامة (المسابقة + الكورسات): بناء **Flutter Web** للمسارات العامة
  (`/courses` + تقديم المسابقة بـ anon key) ونشرها (Vercel/استضافة ثابتة).

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
  الباقي تحذيرات 0029 معروفة (دوال RLS المساعدة، مؤجّلة لـ private schema) +
  leaked-pw (محتاج تأكيد) + INFO واحد (`subscription_overdue_notice` RLS-no-policy،
  مقصود لجدول نظام). الكرونات الجداد مش مكشوفة كـ RPC (execute مسحوب).
