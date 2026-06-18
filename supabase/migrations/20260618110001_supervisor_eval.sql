-- Phase 5 — تقييم المشرف العشوائي (٣ معايير ×١٠): حفظ/تلاوة/قراءة من المصحف.
-- حدث منفصل عن تسميع المعلّم اليومي. (قوالب تقييم مرنة لاحقًا — دلوقتي ٣ معايير ثابتة.)
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.

create type public.eval_selection as enum ('random', 'manual');
create type public.eval_criterion as enum (
  'memorization',
  'recitation',
  'mushaf_reading'
);

create table public.supervisor_evaluation (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circle (id) on delete cascade,
  supervisor_id uuid references public.person (id),
  eval_date date not null default current_date,
  selection public.eval_selection not null default 'random',
  created_at timestamptz not null default now()
);
create index supervisor_evaluation_circle_idx
  on public.supervisor_evaluation (circle_id);

-- درجة معيار لطالب داخل تقييم.
create table public.eval_score (
  id uuid primary key default gen_random_uuid(),
  evaluation_id uuid not null
    references public.supervisor_evaluation (id) on delete cascade,
  student_person_id uuid not null references public.person (id) on delete cascade,
  criterion public.eval_criterion not null,
  score smallint not null check (score between 0 and 10),
  created_at timestamptz not null default now(),
  unique (evaluation_id, student_person_id, criterion)
);
create index eval_score_eval_idx on public.eval_score (evaluation_id);
create index eval_score_student_idx on public.eval_score (student_person_id);

-- ===== RLS =====
-- المشرف/الأدمن يكتبوا؛ المعلّم يقرا حلقته؛ ولي الأمر يقرا درجات ابنه.
alter table public.supervisor_evaluation enable row level security;
create policy supeval_read on public.supervisor_evaluation
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.teaches_circle(circle_id)
  );
create policy supeval_write on public.supervisor_evaluation
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
  )
  with check (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
  );

alter table public.eval_score enable row level security;
create policy evalscore_read on public.eval_score
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.is_guardian_of(student_person_id)
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = eval_score.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  );
create policy evalscore_write on public.eval_score
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
  )
  with check (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
  );
