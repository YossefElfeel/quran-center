-- Phase 1 — دوال RLS المساعدة (مصدر القرار للصلاحيات).
-- كلها security definer + search_path ثابت (يتفادى تحذير function_search_path_mutable
-- وبيسمح للدالة تقرا جداول الهوية لتحديد المستخدم الحالي بغضّ النظر عن RLS).

-- معرّف الـ person للمستخدم الحالي (من جلسة auth).
create or replace function public.current_person_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select au.person_id
  from public.app_user au
  where au.auth_user_id = auth.uid()
$$;

-- هل المستخدم الحالي عنده الدور ده؟
create or replace function public.has_role(target_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.role_assignment ra
    join public.app_user au on au.person_id = ra.person_id
    where au.auth_user_id = auth.uid()
      and ra.role = target_role
  )
$$;

create or replace function public.is_super_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select public.has_role('super_admin'::public.app_role) $$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select public.has_role('admin'::public.app_role) $$;

create or replace function public.is_supervisor()
returns boolean language sql stable security definer set search_path = ''
as $$ select public.has_role('supervisor'::public.app_role) $$;

create or replace function public.is_teacher()
returns boolean language sql stable security definer set search_path = ''
as $$ select public.has_role('teacher'::public.app_role) $$;

create or replace function public.is_parent()
returns boolean language sql stable security definer set search_path = ''
as $$ select public.has_role('parent'::public.app_role) $$;

-- هل المستخدم الحالي ولي أمر للطالب ده؟
create or replace function public.is_guardian_of(target_student uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.guardian_link gl
    join public.app_user au on au.person_id = gl.guardian_person_id
    where au.auth_user_id = auth.uid()
      and gl.student_person_id = target_student
  )
$$;

-- ملاحظة: teaches_circle() هتتضاف مع migration المناهج/الحلقات (محتاجة جدول circle).
