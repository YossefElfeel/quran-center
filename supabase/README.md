# supabase/ — الـ backend المشترك

مصدر الحقيقة لـ schema قاعدة البيانات وسياسات RLS و Edge Functions وبيانات seed. مشترك بين تطبيق الموبايل ولوحة الويب.

```
supabase/
├─ migrations/   # SQL migrations مؤرّخة (schema + RLS policies + helper functions)
├─ functions/    # Edge Functions (invite-user, upload-media, record-tasmee, ...)
└─ seed.sql      # بيانات مرجعية: 114 سورة + الأجزاء/الأحزاب/الصفحات + صف branch افتراضي
```

## ملاحظات
- كل تغيير schema = migration جديد (مفيش تعديل يدوي على القاعدة) — شامل سياسات/دوال RLS.
- دوال RLS المساعدة: `current_person_id()`, `has_role()`, `is_guardian_of()`, `teaches_circle()`, `is_admin()`, `is_supervisor()`, `is_super_admin()`.
- التطبيق على مشروع Supabase مُدار (عبر Supabase CLI محليًا لو اتسطّب، أو عبر الـ dashboard/MCP).
- `service-role key` للوحة الويب server-side فقط — عمره ما يتحط في المتصفح.
