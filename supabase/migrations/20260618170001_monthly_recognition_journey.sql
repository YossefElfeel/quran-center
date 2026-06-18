-- Phase 8 — التكريم + التقييم الشهري + الخطة الشهرية + رحلة الطالب/حق المحفّظ.
-- مرجع القرآن مفيهوش خرائط أجزاء/صفحات، فـ ajza/pages تتساب تُملأ لاحقًا؛
-- الأهم (مين حفّظ أي مدى) متسجّل بـ from_point/to_point + الحلقة + المعلّم.
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.

create type public.monthly_eval_status as enum (
  'draft', 'submitted', 'approved', 'auto_finalized', 'missed'
);

create table public.monthly_study_plan (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circle (id) on delete cascade,
  month date not null,
  curriculum_plan text,
  teaching_method text,
  portions_ref text,
  published boolean not null default false,
  set_by uuid references public.person (id) default public.current_person_id(),
  set_at timestamptz not null default now(),
  unique (circle_id, month)
);
create index msp_circle_idx on public.monthly_study_plan (circle_id, month);

create table public.monthly_student_evaluation (
  id uuid primary key default gen_random_uuid(),
  student_person_id uuid not null references public.person (id) on delete cascade,
  month date not null,
  status public.monthly_eval_status not null default 'draft',
  evaluator_teacher_id uuid references public.person (id) default public.current_person_id(),
  approved_by uuid references public.person (id),
  approved_at timestamptz,
  summary text,
  tasmee_avg numeric(4, 2),
  attendance_rate numeric(4, 3),
  behavior text,
  created_at timestamptz not null default now(),
  unique (student_person_id, month)
);
create index mse_student_idx on public.monthly_student_evaluation (student_person_id, month);

create table public.monthly_top_student (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circle (id) on delete cascade,
  month date not null,
  student_person_id uuid not null references public.person (id) on delete cascade,
  reason text,
  created_at timestamptz not null default now(),
  unique (circle_id, month)
);
create index mts_circle_idx on public.monthly_top_student (circle_id, month);

create table public.student_journey_segment (
  id uuid primary key default gen_random_uuid(),
  student_person_id uuid not null references public.person (id) on delete cascade,
  circle_id uuid not null references public.circle (id) on delete cascade,
  teacher_id uuid references public.person (id),
  from_point text,
  to_point text,
  ajza numeric(5, 2) not null default 0,
  pages integer not null default 0,
  started_at timestamptz not null default now(),
  ended_at timestamptz
);
create index sjs_student_idx on public.student_journey_segment (student_person_id, started_at);
create unique index sjs_one_open
  on public.student_journey_segment (student_person_id, circle_id)
  where ended_at is null;

-- بوابة الاعتماد سيرفر-سايد: المشرف/الأدمن بس يعتمدوا.
create or replace function public.enforce_monthly_eval_approval()
returns trigger
language plpgsql security invoker set search_path = ''
as $$
begin
  if new.status = 'approved' then
    if not (public.is_supervisor() or public.is_admin()
            or public.is_super_admin()) then
      raise exception 'only supervisor/admin can approve monthly evaluation';
    end if;
    new.approved_by := coalesce(new.approved_by, public.current_person_id());
    new.approved_at := coalesce(new.approved_at, now());
  end if;
  return new;
end;
$$;
create trigger mse_approval_guard
  before insert or update on public.monthly_student_evaluation
  for each row execute function public.enforce_monthly_eval_approval();

alter table public.monthly_study_plan enable row level security;
alter table public.monthly_student_evaluation enable row level security;
alter table public.monthly_top_student enable row level security;
alter table public.student_journey_segment enable row level security;

create policy msp_write on public.monthly_study_plan
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.teaches_circle(circle_id)
  )
  with check (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.teaches_circle(circle_id)
  );
create policy msp_read on public.monthly_study_plan
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.teaches_circle(circle_id)
    or exists (
      select 1 from public.enrollment e
      join public.guardian_link gl on gl.student_person_id = e.student_person_id
      where e.circle_id = monthly_study_plan.circle_id
        and gl.guardian_person_id = public.current_person_id()
    )
  );

create policy mse_write on public.monthly_student_evaluation
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = monthly_student_evaluation.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  )
  with check (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = monthly_student_evaluation.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  );
create policy mse_read on public.monthly_student_evaluation
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.is_guardian_of(student_person_id)
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = monthly_student_evaluation.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  );

create policy mts_write on public.monthly_top_student
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.teaches_circle(circle_id)
  )
  with check (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.teaches_circle(circle_id)
  );
create policy mts_read on public.monthly_top_student
  for select to authenticated using (true);

create policy sjs_write on public.student_journey_segment
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or public.teaches_circle(circle_id)
  )
  with check (
    public.is_super_admin() or public.is_admin()
    or public.teaches_circle(circle_id)
  );
create policy sjs_read on public.student_journey_segment
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.is_guardian_of(student_person_id)
    or public.teaches_circle(circle_id)
  );

revoke all on function public.enforce_monthly_eval_approval()
  from public, anon, authenticated;
