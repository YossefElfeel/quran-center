-- M4.2: TTL purge of stale public registrations. Public competition sign-ups older
-- than the retention window that have NOT led to an accepted competition application
-- are deleted; their pending/rejected applications cascade-delete via
-- competition_application.public_registration_id (ON DELETE CASCADE). The deleted
-- count is recorded in audit_log (actor = NULL = system).
--
-- TTL is read from system_settings.public_registration_ttl_days (default 90 days).
-- security definer + search_path='' + revoked from API roles. Idempotent: a second
-- run finds nothing left to purge. cron.schedule upserts by name.

create or replace function public.purge_public_registrations()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ttl integer;
  v_cutoff timestamptz;
  v_count integer := 0;
begin
  v_ttl := coalesce(
    (select value::int from public.system_settings
     where key = 'public_registration_ttl_days'), 90);
  v_cutoff := now() - (v_ttl || ' days')::interval;

  with deleted as (
    delete from public.public_registration pr
    where pr.created_at < v_cutoff
      and not exists (
        select 1 from public.competition_application ca
        where ca.public_registration_id = pr.id
          and ca.status = 'accepted'
      )
    returning 1
  )
  select count(*) into v_count from deleted;

  insert into public.audit_log (actor_person_id, action, target_table, meta)
  values (null, 'cron_purge_public_registrations', 'public_registration',
          jsonb_build_object('deleted', v_count, 'ttl_days', v_ttl,
                             'cutoff', v_cutoff));

  return v_count;
end;
$$;

revoke all on function public.purge_public_registrations() from public, anon, authenticated;

-- Run daily at 03:00.
select cron.schedule(
  'purge-public-registrations',
  '0 3 * * *',
  $cron$ select public.purge_public_registrations(); $cron$
);
