-- M4.2: 48-hour SLA escalation for unanswered complaints.
-- Managers (admin/super_admin) get one in-app notification when an open/reopened
-- complaint passes 48h with no response. Idempotent via complaint.escalated_at.

alter table public.complaint add column if not exists escalated_at timestamptz;

create or replace function public.escalate_overdue_complaints()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer := 0;
  v_id uuid;
begin
  for v_id in
    select id from public.complaint
    where status in ('open', 'reopened')
      and escalated_at is null
      and created_at < now() - interval '48 hours'
    for update skip locked
  loop
    insert into public.notification (recipient_person_id, type, title, body)
    select ra.person_id, 'complaint_overdue', 'شكوى محتاجة رد',
           'فيه شكوى عدّى عليها أكتر من ٤٨ ساعة من غير رد. لو سمحت راجعها وردّ عليها.'
    from public.role_assignment ra
    where ra.role in ('admin', 'super_admin');

    update public.complaint set escalated_at = now() where id = v_id;
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

-- System-only: never callable as a PostgREST RPC.
revoke all on function public.escalate_overdue_complaints() from public, anon, authenticated;

-- Run hourly. cron.schedule upserts by job name, so re-running this migration is safe.
select cron.schedule(
  'escalate-overdue-complaints',
  '0 * * * *',
  $cron$ select public.escalate_overdue_complaints(); $cron$
);
