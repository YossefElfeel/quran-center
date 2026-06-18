-- Phase 7a (إصلاح أمان) — ثغرة: فحص النوع بـ subquery على person جوّا السياسة
-- كان بيتقيّم بصلاحية المستخدم. معلّم مايقدرش يقرا صف البنت → الـ subquery NULL
-- و(NULL is distinct from 'female')=true → تجاوز بوابة الموافقة عند الكتابة.
-- الحل: دالة SECURITY DEFINER تقرا النوع موثوق، والسياستين تستخدماها.
-- اتكشفت بالـ smoke test (girl_blocked=f) واتأكد الإصلاح (girl_blocked=t).

create or replace function public.media_consent_ok(
  p_student uuid, p_type public.media_type
) returns boolean
language sql stable security definer set search_path = ''
as $$
  select (
    (select p.gender from public.person p where p.id = p_student)
      is distinct from 'female'::public.gender
    or public.has_active_media_consent(p_student, p_type)
  );
$$;
revoke all on function public.media_consent_ok(uuid, public.media_type)
  from public, anon;
grant execute on function public.media_consent_ok(uuid, public.media_type)
  to authenticated;

drop policy media_read on public.media;
drop policy media_write on public.media;

create policy media_read on public.media
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = media.student_person_id
        and public.teaches_circle(e.circle_id)
    )
    or (
      public.is_guardian_of(media.student_person_id)
      and public.media_consent_ok(media.student_person_id, media.type)
    )
  );

create policy media_write on public.media
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = media.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  )
  with check (
    (
      public.is_super_admin() or public.is_admin()
      or exists (
        select 1 from public.enrollment e
        where e.student_person_id = media.student_person_id
          and public.teaches_circle(e.circle_id)
      )
    )
    and public.media_consent_ok(media.student_person_id, media.type)
  );
