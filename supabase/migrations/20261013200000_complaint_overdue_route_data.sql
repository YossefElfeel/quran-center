-- Live-check fix: overdue-complaint notices were identical rows with no way to tell which
-- complaint they meant. Attach route_data {complaint_id} (the app shows "#A183" and opens the
-- inbox) and put the short reference in the body. Managers holding both admin and super_admin
-- now get one notice per complaint instead of two. Idempotency via complaint.escalated_at is
-- unchanged; existing notices are left as they are (their complaint cannot be recovered).
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
    insert into public.notification (recipient_person_id, type, title, body, route_data)
    select ra.person_id, 'complaint_overdue', 'شكوى محتاجة رد',
           format('الشكوى #%s عدّى عليها أكتر من ٤٨ ساعة من غير رد. لو سمحت راجعها وردّ عليها.',
                  -- Same code the app shows: last 4 of the 8-char reference number.
                  upper(right(left(replace(v_id::text, '-', ''), 8), 4))),
           jsonb_build_object('complaint_id', v_id)
    from (select distinct person_id from public.role_assignment
          where role in ('admin', 'super_admin')) ra;

    update public.complaint set escalated_at = now() where id = v_id;
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

-- System-only: never callable as a PostgREST RPC.
revoke all on function public.escalate_overdue_complaints() from public, anon, authenticated;
