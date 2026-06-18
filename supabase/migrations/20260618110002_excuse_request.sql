-- Phase 5 — طلب عذر الغياب: المعلّم يطلب، المشرف يوافق → الغياب يبقى محايد.
-- مربوط بالحصة (session_id) عشان الموافقة تحدّث الحضور مباشرة.
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.

create type public.excuse_status as enum ('pending', 'approved', 'rejected');

create table public.excuse_request (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null references public.enrollment (id) on delete cascade,
  session_id uuid references public.circle_session (id) on delete set null,
  reason text,
  status public.excuse_status not null default 'pending',
  decided_by uuid references public.person (id),
  decided_at timestamptz,
  created_at timestamptz not null default now()
);
create index excuse_request_status_idx on public.excuse_request (status);
create index excuse_request_enrollment_idx
  on public.excuse_request (enrollment_id);

-- ===== RLS =====
-- المعلّم (بتاع الحلقة) أو الأدمن ينشئ؛ المشرف/الأدمن يقرّر؛
-- القراءة للمشرف/الأدمن + معلّم الحلقة + ولي أمر الطالب.
alter table public.excuse_request enable row level security;

create policy excuse_select on public.excuse_request
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.teaches_enrollment(enrollment_id)
    or public.is_guardian_of_enrollment(enrollment_id)
  );

create policy excuse_insert on public.excuse_request
  for insert to authenticated
  with check (
    public.is_super_admin() or public.is_admin()
    or public.teaches_enrollment(enrollment_id)
  );

create policy excuse_decide on public.excuse_request
  for update to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
  )
  with check (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
  );
