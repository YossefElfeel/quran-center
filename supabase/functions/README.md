# Edge Functions — حالة النشر

## منشورة (ACTIVE) — 2026-06-18
> الـ service-role key بيتقري من بيئة الـ Edge وقت التشغيل بس (Supabase بيحقنه
> تلقائيًا، والمفتاح المكشوف اتدوّر). الدالتين `verify_jwt=true` (نده بدون توكن → 401،
> متحقّق).

### `invite-user`
الأدمن يدعو ولي أمر/معلّم/مشرف. بيتأكد إن النده أدمن (`is_admin`)، بينشئ `person` +
`role_assignment` (+ `guardian_link` لولي الأمر)، بيولّد رابط دعوة (بينشئ auth user)
ويربط `app_user`. بيرجّع `action_link` (يتبعت للمستخدم — واتساب/إيميل).
**أول دعوة حقيقية بتتعمل من شاشة الأدمن في التطبيق.**

### `submit-public-application`
الصفحة العامة (M7): تقديم مسابقة بتسجيل بسيط (اسم + موبايل + موافقة). بيتأكد من
الموافقة، إن المسابقة مفتوحة، يطبّع الموبايل ويمنع التكرار، وينشئ
`public_registration` + `competition_application(origin='public')`.
**قبل الإنتاج:** rate-limit / OTP على البوابة (مكافحة السبام).

## مؤجّلة

### `upload-media`  ⏸️
رفع صورة/فيديو لطالب بفحص الموافقة (`media_consent_ok`) + تخزين خاص + صف `media`.
**مؤجّلة بسبب العلامة المائية:** Deno Edge مفيهوش `ffmpeg`، فضغط/علامة مائية
للفيديو سيرفر-سايد مش عملي هناك. الخيارات: علامة مائية للصور بس (imagescript)، أو
خدمة ترميز منفصلة، أو overlay كلاينت-سايد. يتحسم قبل تفعيل رفع الفيديو.

### `block-user` · `delete-user` · `manage-role`  ⏸️ (M6 — تحكّم السوبر أدمن)
إدارة دورة حياة المستخدم من لوحة السوبر أدمن (مدقّقة، service-role، نفس نمط `impersonate`):
- **`block-user`** — حظر/فك حظر (`{target_person_id, block, reason}`): بيرفع `person.blocked_at`
  (قفل RLS فوري عبر `private.current_person_id()`/`has_role()`) + `ban` على Auth.
- **`delete-user`** — `mode: soft|hard|restore`. soft = إيقاف ناعم (بيحفظ السجلّ)؛ hard = حذف
  نهائي (بيفصل مراجع الـ FX اللي من غير cascade قبل `auth.admin.deleteUser`، ويطلب `confirm`
  = الاسم الكامل)؛ restore = استرجاع موقوف.
- **`manage-role`** — منح/سحب أي دور (`{target_person_id, role, op}`)؛ حماية آخر سوبر أدمن.

حواجز: سوبر أدمن نشط بس, مايحظرش/يحذفش نفسه, حماية آخر سوبر أدمن نشط, السبب مطلوب.
بتعتمد على migrations `20260619000006` (أعمدة دورة الحياة) + `20260619000007` (بوّابة RLS +
trigger). **قبل التفعيل:** تدوير مفتاح service-role + نشر `supabase functions deploy
block-user delete-user manage-role`.

### `data-console-write`  ⏸️ (M6 P5 — وحدة التحكّم بالبيانات)
كتابة عامّة محروسة من `/data` (سوبر أدمن نشط فقط, service-role, مدقّقة):
`{table, op: insert|update|delete, payload, match, reason}`. حواجز: deny-list
(`app_user`/`audit_log`/`role_assignment` — تُدار بمسارات مخصّصة), تجريد أعمدة الرقم
القومي من أي كتابة, `match` مطلوب للتعديل/الحذف (مايمسحش جدول كامل), السبب مطلوب,
كل عملية في `audit_log`. **قبل التفعيل:** تدوير مفتاح service-role + `supabase functions
deploy data-console-write`.

## النشر (مرجع)
`supabase functions deploy <name>` — أو عبر لوحة Supabase / MCP. الأسرار الأساسية
(`SUPABASE_URL`/`ANON_KEY`/`SERVICE_ROLE_KEY`) Supabase بيوفّرها تلقائيًا للـ Edge.
