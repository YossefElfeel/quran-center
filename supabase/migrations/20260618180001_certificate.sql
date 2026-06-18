-- Phase 9 — شهادات الطلبة. الأهلية = كل المقاطع passed + zero debt (شهادات الإتمام)؛
-- شهادة الشرف (honor) مستثناة (مشتقة من لوحة الشرف مش من الدَيْن).
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.

create type public.certificate_kind as enum ('juz_amma', 'half', 'full', 'honor');

create table public.certificate (
  id uuid primary key default gen_random_uuid(),
  student_person_id uuid not null references public.person (id) on delete cascade,
  kind public.certificate_kind not null,
  issued_at date not null default current_date,
  approved_by uuid references public.person (id),
  issued_by uuid references public.person (id) default public.current_person_id(),
  pdf_url text,
  created_at timestamptz not null default now()
);
create index certificate_student_idx
  on public.certificate (student_person_id, issued_at desc);

-- أهلية الشهادة: عنده مقطع passed على الأقل ومفيش أي مقطع لسه مش passed.
create or replace function public.is_certificate_eligible(p_student uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.portion_ledger_entry
    where student_person_id = p_student and state = 'passed'
  ) and not exists (
    select 1 from public.portion_ledger_entry
    where student_person_id = p_student and state <> 'passed'
  );
$$;
revoke all on function public.is_certificate_eligible(uuid) from public, anon;
grant execute on function public.is_certificate_eligible(uuid) to authenticated;

-- بوابة الإصدار: شهادات الإتمام تتطلب zero-debt؛ honor مستثناة.
create or replace function public.enforce_certificate_eligibility()
returns trigger
language plpgsql security invoker set search_path = ''
as $$
begin
  if new.kind <> 'honor'
     and not public.is_certificate_eligible(new.student_person_id) then
    raise exception 'student not eligible: must pass all portions with zero debt';
  end if;
  return new;
end;
$$;
create trigger certificate_eligibility_guard
  before insert on public.certificate
  for each row execute function public.enforce_certificate_eligibility();
revoke all on function public.enforce_certificate_eligibility()
  from public, anon, authenticated;

alter table public.certificate enable row level security;

create policy certificate_read on public.certificate
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.is_guardian_of(student_person_id)
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = certificate.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  );
create policy certificate_write on public.certificate
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
  )
  with check (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
  );
