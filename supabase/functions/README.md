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

## النشر (مرجع)
`supabase functions deploy <name>` — أو عبر لوحة Supabase / MCP. الأسرار الأساسية
(`SUPABASE_URL`/`ANON_KEY`/`SERVICE_ROLE_KEY`) Supabase بيوفّرها تلقائيًا للـ Edge.
