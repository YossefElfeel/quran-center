-- Phase 4 — helpers للـ RLS على بيانات المحرّك.

-- هل المستخدم الحالي معلّم الحلقة اللي فيها التسجيل ده؟
create or replace function public.teaches_enrollment(target_enrollment uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.enrollment e
    join public.circle c on c.id = e.circle_id
    join public.app_user au on au.person_id = c.teacher_id
    where e.id = target_enrollment and au.auth_user_id = auth.uid()
  )
$$;

-- هل المستخدم الحالي ولي أمر صاحب التسجيل ده؟
create or replace function public.is_guardian_of_enrollment(target_enrollment uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.enrollment e
    where e.id = target_enrollment
      and public.is_guardian_of(e.student_person_id)
  )
$$;

-- تقليل سطح RPC (advisor 0028): execute للـ authenticated بس.
revoke execute on function public.teaches_enrollment(uuid) from public, anon;
grant execute on function public.teaches_enrollment(uuid) to authenticated;
revoke execute on function public.is_guardian_of_enrollment(uuid) from public, anon;
grant execute on function public.is_guardian_of_enrollment(uuid) to authenticated;
