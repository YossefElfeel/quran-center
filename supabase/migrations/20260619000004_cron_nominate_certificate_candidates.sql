-- M4.4: weekly nomination of certificate-eligible students. Eligibility reuses the
-- existing public.eligible_certificate_students() RPC (same rule as
-- is_certificate_eligible: at least one portion passed and no portion still
-- outstanding => "zero portion debt"; a student carrying any non-passed portion is
-- excluded). Newly eligible students who do not already hold a certificate and were
-- not nominated before are queued for the supervisor by notifying supervisors/admins.
-- This does NOT issue a certificate — the supervisor still approves the final exam.
-- Idempotency is tracked in certificate_nomination.
-- actor = NULL = system. security definer + search_path='' + revoked from API roles.

create table if not exists public.certificate_nomination (
  student_person_id uuid primary key references public.person (id) on delete cascade,
  nominated_at timestamptz not null default now()
);
-- System-only table (no policies => deny-all for API roles; cron writes via definer).
alter table public.certificate_nomination enable row level security;

create or replace function public.nominate_certificate_candidates()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_new uuid[];
  v_count integer := 0;
begin
  with cand as (
    select ecs.id
    from public.eligible_certificate_students() ecs
    where not exists (select 1 from public.certificate c
                      where c.student_person_id = ecs.id)
      and not exists (select 1 from public.certificate_nomination n
                      where n.student_person_id = ecs.id)
  ),
  ins as (
    insert into public.certificate_nomination (student_person_id)
    select id from cand
    on conflict (student_person_id) do nothing
    returning student_person_id
  )
  select coalesce(array_agg(student_person_id), '{}'::uuid[]) into v_new from ins;

  v_count := coalesce(array_length(v_new, 1), 0);

  if v_count > 0 then
    insert into public.notification (recipient_person_id, type, title, body)
    select ra.person_id, 'certificate_candidate', 'مرشّحون لشهادة إتمام',
           'فيه طلبة كمّلوا كل المقاطع ومؤهّلين لشهادة إتمام. لو سمحت راجع وادعُهم للامتحان النهائي.'
    from public.role_assignment ra
    where ra.role in ('supervisor', 'admin', 'super_admin');
  end if;

  insert into public.audit_log (actor_person_id, action, target_table, meta)
  values (null, 'cron_nominate_certificate_candidates', 'certificate_nomination',
          jsonb_build_object('nominated', v_count));

  return v_count;
end;
$$;

revoke all on function public.nominate_certificate_candidates() from public, anon, authenticated;

-- Run weekly on Monday at 05:00.
select cron.schedule(
  'nominate-certificate-candidates',
  '0 5 * * 1',
  $cron$ select public.nominate_certificate_candidates(); $cron$
);
