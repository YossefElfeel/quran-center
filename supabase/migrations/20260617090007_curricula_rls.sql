-- Phase 1 — teaches_circle() + RLS لجداول المناهج/الحلقات.
-- (سياسات أولية؛ تتدقّق باختبارات pgTAP بعد التطبيق.)

create or replace function public.teaches_circle(target_circle uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.circle c
    join public.app_user au on au.person_id = c.teacher_id
    where au.auth_user_id = auth.uid()
      and c.id = target_circle
  )
$$;

-- ===== curriculum & level: مرجع غير حسّاس — قراءة لأي مسجّل، كتابة سوبر/أدمن =====
alter table public.curriculum enable row level security;
create policy curriculum_read on public.curriculum
  for select to authenticated using (true);
create policy curriculum_admin_write on public.curriculum
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());

alter table public.level enable row level security;
create policy level_read on public.level
  for select to authenticated using (true);
create policy level_admin_write on public.level
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());

-- ===== circle =====
alter table public.circle enable row level security;
-- الطاقم الإشرافي يقرا الكل؛ المعلّم يقرا حلقاته؛ ولي الأمر يقرا حلقات أبنائه.
create policy circle_staff_read on public.circle
  for select to authenticated
  using (public.is_super_admin() or public.is_admin() or public.is_supervisor());
create policy circle_teacher_read on public.circle
  for select to authenticated
  using (teacher_id = public.current_person_id());
create policy circle_parent_read on public.circle
  for select to authenticated
  using (
    exists (
      select 1 from public.enrollment e
      where e.circle_id = circle.id
        and public.is_guardian_of(e.student_person_id)
    )
  );
create policy circle_admin_write on public.circle
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());

-- ===== enrollment =====
alter table public.enrollment enable row level security;
create policy enrollment_staff_read on public.enrollment
  for select to authenticated
  using (public.is_super_admin() or public.is_admin() or public.is_supervisor());
create policy enrollment_teacher_read on public.enrollment
  for select to authenticated
  using (public.teaches_circle(circle_id));
create policy enrollment_parent_read on public.enrollment
  for select to authenticated
  using (public.is_guardian_of(student_person_id));
-- الكتابة: سوبر/أدمن/مشرف (التسجيل والإسناد لحلقة).
create policy enrollment_staff_write on public.enrollment
  for all to authenticated
  using (public.is_super_admin() or public.is_admin() or public.is_supervisor())
  with check (public.is_super_admin() or public.is_admin() or public.is_supervisor());

-- ===== waiting_list =====
alter table public.waiting_list enable row level security;
create policy waiting_list_staff_all on public.waiting_list
  for all to authenticated
  using (public.is_super_admin() or public.is_admin() or public.is_supervisor())
  with check (public.is_super_admin() or public.is_admin() or public.is_supervisor());
create policy waiting_list_parent_read on public.waiting_list
  for select to authenticated
  using (public.is_guardian_of(student_person_id));

-- ===== placement_test =====
alter table public.placement_test enable row level security;
create policy placement_staff_read on public.placement_test
  for select to authenticated
  using (public.is_super_admin() or public.is_admin() or public.is_supervisor());
create policy placement_parent_read on public.placement_test
  for select to authenticated
  using (public.is_guardian_of(student_person_id));
create policy placement_staff_write on public.placement_test
  for all to authenticated
  using (public.is_super_admin() or public.is_admin() or public.is_supervisor())
  with check (public.is_super_admin() or public.is_admin() or public.is_supervisor());
