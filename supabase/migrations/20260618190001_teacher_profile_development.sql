-- Phase 10 — ملف المعلّم (أدمن + نفسه) + تطوّره (يسجّل → المشرف يعتمد) + مؤشّر أداء.
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.

create table public.teacher_profile (
  teacher_person_id uuid primary key references public.person (id) on delete cascade,
  cv text,
  photo_url text,
  qualifications jsonb not null default '[]'::jsonb,
  certificates jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table public.teacher_development (
  id uuid primary key default gen_random_uuid(),
  teacher_person_id uuid not null references public.person (id) on delete cascade,
  month date not null,
  memorization_progress text,
  ijazah jsonb not null default '[]'::jsonb,
  courses jsonb not null default '[]'::jsonb,
  status public.monthly_eval_status not null default 'draft',
  approved_by uuid references public.person (id),
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  unique (teacher_person_id, month)
);
create index teacher_dev_idx on public.teacher_development (teacher_person_id, month);

-- مؤشّر أداء: نسبة نجاح طلبة المعلّم (من دفتر المقاطع لطلبة حلقاته النشطة).
create or replace function public.teacher_pass_rate(p_teacher uuid)
returns numeric
language sql stable security definer set search_path = ''
as $$
  select case
    when count(*) = 0 then 0
    else round(
      count(*) filter (where ple.state = 'passed')::numeric / count(*), 3)
  end
  from public.portion_ledger_entry ple
  join public.enrollment e
    on e.student_person_id = ple.student_person_id and e.status = 'active'
  join public.circle c on c.id = e.circle_id
  where c.teacher_id = p_teacher;
$$;
revoke all on function public.teacher_pass_rate(uuid) from public, anon;
grant execute on function public.teacher_pass_rate(uuid) to authenticated;

-- بوابة اعتماد التطوّر: المشرف/الأدمن بس.
create or replace function public.enforce_dev_approval()
returns trigger
language plpgsql security invoker set search_path = ''
as $$
begin
  if new.status = 'approved' then
    if not (public.is_supervisor() or public.is_admin()
            or public.is_super_admin()) then
      raise exception 'only supervisor/admin can approve development';
    end if;
    new.approved_by := coalesce(new.approved_by, public.current_person_id());
    new.approved_at := coalesce(new.approved_at, now());
  end if;
  return new;
end;
$$;
create trigger teacher_dev_approval_guard
  before insert or update on public.teacher_development
  for each row execute function public.enforce_dev_approval();
revoke all on function public.enforce_dev_approval()
  from public, anon, authenticated;

alter table public.teacher_profile enable row level security;
alter table public.teacher_development enable row level security;

create policy tprofile_read on public.teacher_profile
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or teacher_person_id = public.current_person_id()
  );
create policy tprofile_write on public.teacher_profile
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or teacher_person_id = public.current_person_id()
  )
  with check (
    public.is_super_admin() or public.is_admin()
    or teacher_person_id = public.current_person_id()
  );

create policy tdev_read on public.teacher_development
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or teacher_person_id = public.current_person_id()
  );
create policy tdev_write on public.teacher_development
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or teacher_person_id = public.current_person_id()
  )
  with check (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or teacher_person_id = public.current_person_id()
  );
