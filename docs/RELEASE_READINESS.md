# جاهزية الإطلاق (Release Readiness) — Phase 14

> الحالة: نواة المنصة (Phases 0–13) مبنية ومتحقّق منها (analyze نضيف، اختبارات
> خضراء، smoke tests لكل migration، RLS متحقّق structurally + بمحاكاة دخول).
> الملف ده بيوثّق اللي **لسه محتاج خطوات يدوية/خارجية** قبل الإطلاق — حاجات
> بطبيعتها مش بتتعمل تلقائيًا (مفاتيح، توقيع، نشر، تبديلات لوحة).

---

## 1) أمان لازم قبل أي نشر

### (أ) تدوير المفتاح السري المكشوف — **حرج**
المفتاح (`sb_secret_…`) اتعرض في الشات قبل كده. **لازم يتدوّر** من
Supabase → Settings → API → Rotate. مفيش أي Edge Function اتنشرت بالمفتاح ده،
ومفيش حسابات اتعملت بيه. لا تنشر `invite-user`/`upload-media`/
`submit-public-application` قبل التدوير.

### (ب) تفعيل حماية الباسوردات المسرّبة (advisor: auth_leaked_password_protection)
Supabase → Authentication → Policies → فعّل "Leaked password protection"
(HaveIBeenPwned). تبديل لوحة، مش كود.

### (ج) advisor 0029/0028 — نقل دوال RLS المساعدة لـ schema خاص
دوال الـ SECURITY DEFINER المساعدة كلها في `public` فبتظهر كـ RPC للـ
`authenticated` (تسريب بسيط: بوليانات عن المستخدم الحالي/علاقاته). الإصلاح
المخطّط (محتاج اختبارات integration كاملة شغّالة قبل التطبيق عشان مايكسرش الـ RLS):

- أنشئ schema `private` (مش مكشوف عبر PostgREST).
- **انقل لـ private** الدوال اللي تُستخدم **جوّا السياسات بس**:
  `current_person_id, has_role, is_admin, is_super_admin, is_supervisor,
  is_teacher, is_parent, is_guardian_of, is_guardian_of_enrollment,
  teaches_circle, teaches_enrollment, is_competition_judge,
  is_parent_of_teachers_student, has_active_media_consent, media_consent_ok,
  is_certificate_eligible, household_has_active_subscription,
  person_has_active_subscription, rls_auto_enable`.
  وحدّث **كل** السياسات اللي بتشير لها لـ `private.fn(...)` + `grant execute`
  للـ authenticated على نسخ private.
- **تفضل في public** (لأن التطبيق بينده عليها كـ RPC):
  `record_tasmee, my_subscription_active, households_with_status,
  circle_pass_rates, teacher_pass_rate, log_media_access`.
  (دي مقبولة تتنده من المستخدم؛ لو حبيت تشدّد، اعمل wrappers رفيعة في public
  بتنده private وتتأكد من الصلاحية.)
- بعد التطبيق: شغّل smoke الـ RLS (موجود في الـ migrations) + اختبارات وصول
  سلبية للتأكد إن العزل لسه شغّال.

> ملاحظة: دي WARN مش error، والتسريب محدود؛ اتأجّلت عمدًا عشان إعادة كتابة ~40
> سياسة بدون integration suite شغّال خطر على طبقة الأمان كلها.

### (د) حضانة مفتاح الرقم القومي (PDPL)
`national_id_hmac` (blind index) + `national_id_encrypted`. المفاتيح تتحط في
Supabase Vault (مش في الكود)، وتتوثّق سياسة تدوير. استشارة قانونية PDPL قبل
جمع بيانات حقيقية.

---

## 2) Edge Functions للنشر (source جاهز، deploy متأجّل)
بعد تدوير المفتاح + ضبط الـ secrets (`supabase secrets set ...`):
- `invite-user` — دعوة مستخدم (أدمن) → بيعمل auth user + person + role.
- `upload-media` — رفع وسائط بفحص الموافقة. **TODO قبل الإنتاج: علامة مائية +
  ضغط فيديو سيرفر-سايد.**
- `submit-public-application` — تقديم عام للمسابقة (consent + dedupe موبايل).
- نشر: `supabase functions deploy <name>`.

## 3) Cron (pg_cron / Edge scheduled) — مطلوب إعداد
- **قفل الشهر**: مسوّدات `monthly_student_evaluation` + تقرير الحلقة + بطاقات
  التقدّم + تدوير الاشتراك + تصعيد الـ missed.
- **تصعيد الشكاوى ٤٨س** (`complaint` open بعد 48h → المدير + أدمن احتياطي).
- **حذف TTL** لتسجيلات العامة المنتهية (`public_registration`/الطلبات المرفوضة).
- **احتفاظ الوسائط**: عند تخرّج/ترك الطالب → سيب أول + آخر فيديو بس (manifest +
  نافذة استرجاع، actor=system).
- **اعتماد تلقائي للتقييم الشهري** لو المعلّم ما سلّمش (auto_finalized).

## 4) الإطلاق (Android) — يدوي/خارجي
- توقيع التطبيق (keystore) + R8/ProGuard + أيقونة + بيان متجر عربي.
- `flutter build appbundle --flavor prod` → Google Play internal testing → إطلاق.
- الصفحة العامة (المسابقة + الكورسات): بناء **Flutter Web** للمسارات العامة
  (`/courses` + تقديم المسابقة بـ anon key) ونشرها (Vercel/استضافة ثابتة).

## 5) لوحة السوبر أدمن (Track D — Next.js) — لسه ما اتبنتش
D0 scaffolding اتعمل بس. D1–D4 (إدارة مستخدمين/إعدادات، تدقيق، تحليلات،
تقمّص الدور) مسار متوازي منفصل.

---

## 6) UI مؤجّل (الـ backend جاهز ومتحقّق منه)
- **Phase 7a**: معرض الوسائط (محتاج `upload-media` + signed URLs منشورين).
- **Phase 7b**: شاشة دعوة المستخدمين (محتاجة `invite-user` منشورة).
- **Phase 8**: لوحة الشرف، تأليف/اعتماد التقييم الشهري، تراكم الرحلة التلقائي
  عند النجاح/النقل.
- **Phase 9**: تقارير PDF تانية (كشف حضور، بطاقة تقدّم، تقرير حلقة شهري)؛ شاشة
  إصدار الشهادة للمشرف/الأدمن (`issueCertificate` + البوابة جاهزين).
- **Phase 10**: محرّر ملف المعلّم الكامل (cv/صورة/مؤهّلات).
- **Phase 11**: تصعيد الشكاوى ٤٨س (cron)، عارض تقييمات المحفّظ للمدير.
- **Phase 12**: محرّر الفئات/الجولات، تضمين يوتيوب في التحكيم، per-criterion.
- **Phase 13**: الصفحة العامة (Flutter Web) + TTL cron.

---

## 7) اللي متحقّق منه فعلاً (Phase 14 audit)
- **عزل RLS** (مصفوفة): ولي الأمر يشوف بيانات ابنه بس؛ المعلّم يشوف طلبة حلقته
  بس (smoke: `g1_certs=1, g1_sees_s2=0, t1_certs=1`).
- **بوابات الاعتماد سيرفر-سايد**: التقييم الشهري + تطوّر المعلّم (المشرف بس)،
  أهلية الشهادة (zero-debt)، موافقة وسائط البنت (قراءة+كتابة)، المعلّم أعمى عن
  تقييمه، الشكوى للمدير بس.
- **سياسة الأنيميشن**: مفيش `.repeat(` في الكود (حارس CI).
- **CI**: `flutter analyze` نضيف + `dart format` + الاختبارات خضراء + build_runner.
- **advisors**: مفيش جدول من غير RLS؛ التحذيرات المعروفة بس (0029/0028/leaked-pw)
  موثّقة فوق بخطة إصلاح.
