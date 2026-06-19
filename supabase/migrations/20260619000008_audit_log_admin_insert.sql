-- M6 P2 — سياسة INSERT على audit_log للسوبر أدمن/الأدمن.
-- الكتابة الحسّاسة (حظر/حذف/أدوار) بتتم من Edge functions بـ service-role (بتتخطّى RLS)،
-- لكن server actions في اللوحة بتكتب تدقيق العمليات العادية (إنشاء/تعديل منهج/حلقة...)
-- بهوية المستخدم عبر RLS — فمحتاجين سياسة INSERT. بنقيّد actor_person_id إنه = الشخص
-- الحالي (مايقدرش ينسب الفعل لحدّ تاني). الدوال في schema private بعد نقلها (20260618270001).
create policy audit_admin_insert on public.audit_log
  for insert to authenticated
  with check (
    (private.is_super_admin() or private.is_admin())
    and actor_person_id = private.current_person_id()
  );
