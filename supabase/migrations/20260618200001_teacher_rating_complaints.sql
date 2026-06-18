-- Phase 11 — تقييم ولي الأمر للمحفّظ (خاص للمدير/المشرف، المعلّم مايشوفوش) + الشكاوى.
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.

create type public.complaint_category as enum (
  'academic', 'financial', 'behavioral', 'privacy', 'other'
);
create type public.complaint_status as enum (
  'open', 'answered', 'reopened', 'closed'
);

create or replace function public.is_parent_of_teachers_student(p_teacher uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.guardian_link gl
    join public.app_user au on au.person_id = gl.guardian_person_id
    join public.enrollment e
      on e.student_person_id = gl.student_person_id and e.status = 'active'
    join public.circle c on c.id = e.circle_id
    where au.auth_user_id = auth.uid() and c.teacher_id = p_teacher
  );
$$;
revoke all on function public.is_parent_of_teachers_student(uuid) from public, anon;
grant execute on function public.is_parent_of_teachers_student(uuid)
  to authenticated;

create table public.teacher_rating (
  id uuid primary key default gen_random_uuid(),
  teacher_person_id uuid not null references public.person (id) on delete cascade,
  parent_person_id uuid not null default public.current_person_id()
    references public.person (id),
  period date not null,
  stars smallint not null check (stars between 1 and 5),
  comment text,
  hidden_by_manager boolean not null default false,
  hidden_reason text,
  created_at timestamptz not null default now(),
  unique (teacher_person_id, parent_person_id, period)
);
create index teacher_rating_teacher_idx
  on public.teacher_rating (teacher_person_id);

create table public.complaint (
  id uuid primary key default gen_random_uuid(),
  author_person_id uuid not null default public.current_person_id()
    references public.person (id),
  category public.complaint_category not null default 'other',
  body text not null check (length(btrim(body)) > 0),
  status public.complaint_status not null default 'open',
  manager_response text,
  responded_at timestamptz,
  created_at timestamptz not null default now()
);
create index complaint_status_idx on public.complaint (status, created_at);

alter table public.teacher_rating enable row level security;
alter table public.complaint enable row level security;

-- تقييم المحفّظ: المدير/المشرف + الكاتب يقروا؛ **المعلّم مستبعد**.
create policy trating_read on public.teacher_rating
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or parent_person_id = public.current_person_id()
  );
create policy trating_insert on public.teacher_rating
  for insert to authenticated
  with check (
    parent_person_id = public.current_person_id()
    and public.is_parent_of_teachers_student(teacher_person_id)
  );
create policy trating_manage on public.teacher_rating
  for update to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());

-- الشكاوى: المدير يقرا الكل + الكاتب يقرا بتاعته؛ الرد للمدير بس.
create policy complaint_read on public.complaint
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or author_person_id = public.current_person_id()
  );
create policy complaint_insert on public.complaint
  for insert to authenticated
  with check (author_person_id = public.current_person_id());
create policy complaint_manage on public.complaint
  for update to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());
