-- Phase 12 — المسابقة: مسابقة/فئات/متقدّمون (داخلي XOR عام)/محكّمون/درجات.
-- التحكيم بدرجة لكل محكّم لكل متقدّم؛ الترتيب + كسر التعادل في الدومين (Dart).
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.

create type public.competition_status as enum ('draft', 'open', 'judging', 'closed');
create type public.application_origin as enum ('internal_student', 'public');
create type public.application_status as enum ('pending', 'accepted', 'rejected');

create table public.public_registration (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  created_at timestamptz not null default now()
);

create table public.competition (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  year smallint,
  status public.competition_status not null default 'draft',
  created_at timestamptz not null default now()
);

create table public.competition_category (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competition (id) on delete cascade,
  name text not null,
  min_age smallint,
  max_age smallint
);
create index comp_category_idx on public.competition_category (competition_id);

create table public.competition_application (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competition (id) on delete cascade,
  category_id uuid references public.competition_category (id) on delete set null,
  origin public.application_origin not null,
  student_person_id uuid references public.person (id) on delete cascade,
  public_registration_id uuid references public.public_registration (id) on delete cascade,
  status public.application_status not null default 'pending',
  youtube_url text,
  created_at timestamptz not null default now(),
  check (
    (student_person_id is not null)::int
    + (public_registration_id is not null)::int = 1
  )
);
create index comp_app_idx on public.competition_application (competition_id, status);

create table public.competition_judge (
  competition_id uuid not null references public.competition (id) on delete cascade,
  judge_person_id uuid not null references public.person (id) on delete cascade,
  primary key (competition_id, judge_person_id)
);

create table public.competition_score (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.competition_application (id) on delete cascade,
  judge_person_id uuid not null default public.current_person_id()
    references public.person (id),
  score numeric(5, 2) not null check (score between 0 and 100),
  notes text,
  created_at timestamptz not null default now(),
  unique (application_id, judge_person_id)
);
create index comp_score_app_idx on public.competition_score (application_id);

create or replace function public.is_competition_judge(p_competition uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.competition_judge cj
    join public.app_user au on au.person_id = cj.judge_person_id
    where au.auth_user_id = auth.uid() and cj.competition_id = p_competition
  );
$$;
revoke all on function public.is_competition_judge(uuid) from public, anon;
grant execute on function public.is_competition_judge(uuid) to authenticated;

alter table public.public_registration enable row level security;
alter table public.competition enable row level security;
alter table public.competition_category enable row level security;
alter table public.competition_application enable row level security;
alter table public.competition_judge enable row level security;
alter table public.competition_score enable row level security;

create policy pubreg_admin on public.public_registration
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());

create policy comp_read on public.competition
  for select to authenticated using (true);
create policy comp_write on public.competition
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());
create policy compcat_read on public.competition_category
  for select to authenticated using (true);
create policy compcat_write on public.competition_category
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());

create policy compapp_read on public.competition_application
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or public.is_competition_judge(competition_id)
  );
create policy compapp_write on public.competition_application
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());

create policy compjudge_read on public.competition_judge
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or judge_person_id = public.current_person_id()
  );
create policy compjudge_write on public.competition_judge
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());

create policy compscore_read on public.competition_score
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or judge_person_id = public.current_person_id()
  );
create policy compscore_write on public.competition_score
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or judge_person_id = public.current_person_id()
  )
  with check (
    (public.is_super_admin() or public.is_admin())
    or (
      judge_person_id = public.current_person_id()
      and exists (
        select 1 from public.competition_application ca
        where ca.id = competition_score.application_id
          and public.is_competition_judge(ca.competition_id)
      )
    )
  );
