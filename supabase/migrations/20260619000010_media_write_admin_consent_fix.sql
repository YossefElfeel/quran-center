-- M6 P4 — إصلاح: السوبر أدمن/الأدمن يقدر يدير الوسائط (حذف ناعم retained / استرجاع)
-- بغضّ النظر عن بوّابة الموافقة. الـ with check القديم (20260618160003) كان بيفرض
-- media_consent_ok حتى على الأدمن، فالـ UPDATE (toggle retained) كان بيفشل لوسائط البنات
-- اللي من غير موافقة، بينما الحذف النهائي (DELETE، using فقط) بيعدّي — عكس المطلوب.
-- بوّابة الموافقة تخصّ رفع المعلّم، مش إشراف الأدمن. الدوال في schema private بعد النقل.
drop policy media_write on public.media;
create policy media_write on public.media
  for all to authenticated
  using (
    private.is_super_admin() or private.is_admin()
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = media.student_person_id
        and private.teaches_circle(e.circle_id)
    )
  )
  with check (
    private.is_super_admin() or private.is_admin()
    or (
      exists (
        select 1 from public.enrollment e
        where e.student_person_id = media.student_person_id
          and private.teaches_circle(e.circle_id)
      )
      and private.media_consent_ok(media.student_person_id, media.type)
    )
  );
