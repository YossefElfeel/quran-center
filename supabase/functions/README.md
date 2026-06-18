# Edge Functions — حالة النشر

> ⚠️ كل الدوال هنا **scaffold (مصدر فقط)** — لسه **ماتنشرتش**. بتلمس
> `service-role` key، فالنشر بيستنى خطوات يدوية من صاحب المشروع.

## قبل أي نشر (إلزامي)

1. **تدوير المفتاح السري المكشوف**: المفتاح (`sb_secret_…`) اتعرض في الشات قبل
   كده. لازم يتدوّر من Supabase → Settings → API → "Rotate" قبل أي استخدام.
   مفيش أي حساب/مفتاح بيتعمل بالمفتاح القديم.
2. ضبط الـ secrets للدوال:
   ```
   supabase secrets set SUPABASE_URL=... \
     SUPABASE_ANON_KEY=... \
     SUPABASE_SERVICE_ROLE_KEY=<المفتاح المدوّر>
   ```

## الدوال

### `invite-user`  (Phase 7b)
الأدمن يدعو ولي أمر/معلّم/مشرف. بيتأكد إن النده أدمن، بينشئ `person` +
`role_assignment` (+ `guardian_link` لولي الأمر)، بيولّد رابط دعوة (بينشئ
auth user) ويربط `app_user`. النشر:
```
supabase functions deploy invite-user
```
بعد النشر: اعمل شاشة أدمن "دعوة مستخدم" بتنده الدالة، وفعّل بعدها فلو "set
password" من رابط الدعوة. (الباسورد بريسيت/الدخول موجود أصلًا في
`features/auth`.)

### `upload-media`  (Phase 7a)
المعلّم/الأدمن يرفع صورة/فيديو لطالب. بيتأكد من الموافقة (`media_consent_ok`)
قبل التخزين، بيرفع في bucket `media` الخاص، ويسجّل صف في `public.media`.
**TODO قبل الإنتاج:** علامة مائية + ضغط الفيديو سيرفر-سايد.
```
supabase functions deploy upload-media
```

## ليه مؤجّل؟
النشر فعل خارجي بيلمس مفتاح حسّاس وبينشئ حسابات حقيقية. اتساب كـ scaffold
موثّق عشان صاحب المشروع ينشره بإيده بعد تدوير المفتاح — مش بيتعمل تلقائيًا.
