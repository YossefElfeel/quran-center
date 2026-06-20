-- M6 — إنفاذ الحظر/الإيقاف عبر بوّابة مركزية واحدة.
-- كل سياسات RLS في النظام بتمرّ عبر private.current_person_id() و private.has_role()
-- (اتنقلوا لـ schema private في 20260618270001). لو حقنّا فيهم شرط "person نشط"
-- (blocked_at/deactivated_at IS NULL) => المستخدم المحظور يبقى بلا هوية وبلا أدوار في
-- كل الجداول دفعة واحدة. بنبوّب كمان دوال الهوية الورقية اللي بتحلّ المستخدم عبر auth.uid()
-- (is_guardian_of, teaches_circle, teaches_enrollment, is_competition_judge,
-- is_parent_of_teachers_student) عشان توكن المحظور المتبقّي (≤ساعة) ما يقدرش يستغلهم.
--
-- متوافق رجعيًا: الإضافة الوحيدة هي AND ... IS NULL، صحيحة لكل الصفوف الحالية =>
-- supabase/tests/rls_isolation.sql يفضل "RLS OK". Edge functions بتستخدم service-role
-- وبتتخطّى RLS، فعمليات الأدمن (حظر/فك/حذف) شغّالة عادي.

-- مساعد صريح (للاستخدام المستقبلي + قراءة النية).
create or replace function private.is_active_person(p_person uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.person p
    where p.id = p_person and p.blocked_at is null and p.deactivated_at is null
  )
$$;
grant execute on function private.is_active_person(uuid) to authenticated, anon;

-- 1) معرّف الـ person للمستخدم الحالي — NULL لو محظور/موقوف.
create or replace function private.current_person_id()
returns uuid language sql stable security definer set search_path = ''
as $$
  select au.person_id
  from public.app_user au
  join public.person p on p.id = au.person_id
  where au.auth_user_id = auth.uid()
    and p.blocked_at is null
    and p.deactivated_at is null
$$;

-- 2) هل المستخدم الحالي عنده الدور ده؟ — false لو محظور/موقوف (يفقد كل صلاحيات الأدوار).
create or replace function private.has_role(target_role public.app_role)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.role_assignment ra
    join public.app_user au on au.person_id = ra.person_id
    join public.person p on p.id = ra.person_id
    where au.auth_user_id = auth.uid()
      and ra.role = target_role
      and p.blocked_at is null
      and p.deactivated_at is null
  )
$$;

-- 3) دوال الهوية الورقية — نفس البوّابة (تقفل التوكن المتبقّي للمحظور).
create or replace function private.is_guardian_of(target_student uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.guardian_link gl
    join public.app_user au on au.person_id = gl.guardian_person_id
    join public.person p on p.id = gl.guardian_person_id
    where au.auth_user_id = auth.uid()
      and gl.student_person_id = target_student
      and p.blocked_at is null
      and p.deactivated_at is null
  )
$$;

create or replace function private.teaches_circle(target_circle uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.circle c
    join public.app_user au on au.person_id = c.teacher_id
    join public.person p on p.id = c.teacher_id
    where au.auth_user_id = auth.uid()
      and c.id = target_circle
      and p.blocked_at is null
      and p.deactivated_at is null
  )
$$;

-- 3b) دوال الهوية الإضافية اللي بتحلّ المستخدم الحالي عبر auth.uid() لازم تتبوّب برضه،
--     وإلا توكن المحظور المتبقّي (≤ساعة) يفضل يعدّي منها. الأهم: teaches_enrollment
--     (تسميع/دفتر — أهم كتابة في المحرّك)، is_competition_judge، is_parent_of_teachers_student.
create or replace function private.teaches_enrollment(target_enrollment uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.enrollment e
    join public.circle c on c.id = e.circle_id
    join public.app_user au on au.person_id = c.teacher_id
    join public.person p on p.id = c.teacher_id
    where e.id = target_enrollment
      and au.auth_user_id = auth.uid()
      and p.blocked_at is null
      and p.deactivated_at is null
  )
$$;

create or replace function private.is_competition_judge(p_competition uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.competition_judge cj
    join public.app_user au on au.person_id = cj.judge_person_id
    join public.person p on p.id = cj.judge_person_id
    where au.auth_user_id = auth.uid()
      and cj.competition_id = p_competition
      and p.blocked_at is null
      and p.deactivated_at is null
  )
$$;

create or replace function private.is_parent_of_teachers_student(p_teacher uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.guardian_link gl
    join public.app_user au on au.person_id = gl.guardian_person_id
    join public.person p on p.id = gl.guardian_person_id
    join public.enrollment e
      on e.student_person_id = gl.student_person_id and e.status = 'active'
    join public.circle c on c.id = e.circle_id
    where au.auth_user_id = auth.uid()
      and c.teacher_id = p_teacher
      and p.blocked_at is null
      and p.deactivated_at is null
  )
$$;

-- 4) حماية آخر super_admin "نشط" (دفاع في العمق حتى من SQL editor، مش بس Edge function).
--    بنعدّ السوبر أدمن النشطين بس (مش المحظورين/الموقوفين): مينفعش نشيل آخر واحد نشط.
--    إزالة دور سوبر أدمن لشخص محظور/موقوف مسموحة (مبتقلّلش عدد النشطين).
--    security definer عشان الـ count يشوف كل الصفوف رغم RLS.
create or replace function public.enforce_last_super_admin()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare v_other_active int;
begin
  if old.role = 'super_admin'::public.app_role
     and (tg_op = 'DELETE'
          or (tg_op = 'UPDATE' and new.role is distinct from 'super_admin'::public.app_role)) then
    select count(*) into v_other_active
    from public.role_assignment ra
    join public.person p on p.id = ra.person_id
    where ra.role = 'super_admin'::public.app_role
      and ra.person_id <> old.person_id
      and p.blocked_at is null and p.deactivated_at is null;
    -- نمنع بس لو الصف ده لشخص نشط (إزالته بتقلّل النشطين) ومفيش سوبر أدمن نشط تاني.
    if v_other_active = 0 and exists (
      select 1 from public.person p
      where p.id = old.person_id and p.blocked_at is null and p.deactivated_at is null
    ) then
      raise exception 'cannot remove the last active super_admin' using errcode = '23514';
    end if;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

drop trigger if exists role_assignment_protect_last_super on public.role_assignment;
create trigger role_assignment_protect_last_super
  before delete or update on public.role_assignment
  for each row execute function public.enforce_last_super_admin();

-- دالة الـ trigger مش محتاجة EXECUTE كـ RPC (الـ trigger بيشتغل بغضّ النظر عن صلاحية النده).
-- بنسحب التنفيذ عشان متبانش في سطح PostgREST RPC (يقفل advisor 0028/0029).
revoke execute on function public.enforce_last_super_admin() from public, anon, authenticated;
