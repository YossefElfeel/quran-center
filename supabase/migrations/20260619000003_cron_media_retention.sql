-- M4.3: media retention for departed students. Once a student has no active
-- enrollment (all enrollments graduated/dropped/transferred, or only paused), we
-- keep only their first and last *video* and mark the rest retained=false. This is
-- a soft flag (recovery window), NOT a delete; a later job/admin can purge or
-- restore. Students who still have an active enrollment, or an application in an
-- open/judging competition, are skipped. actor = NULL = system.
--
-- NOTE: depends on M3.2 (media upload) for real input; the logic is in place so its
-- effect appears with the first uploaded media. A complaint-linked exclusion is not
-- expressible in the current schema (complaint has no media/student link) and is
-- therefore omitted.
--
-- security definer + search_path='' + revoked from API roles. Idempotent: re-running
-- keeps the same first/last and leaves already-demoted rows untouched.

create or replace function public.run_media_retention()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer := 0;
begin
  with departed as (
    -- students who own media, have at least one enrollment, and none still active
    select m.student_person_id
    from public.media m
    where exists (select 1 from public.enrollment e
                  where e.student_person_id = m.student_person_id)
      and not exists (select 1 from public.enrollment e
                      where e.student_person_id = m.student_person_id
                        and e.status = 'active')
      and not exists (
        select 1 from public.competition_application ca
        join public.competition c on c.id = ca.competition_id
        where ca.student_person_id = m.student_person_id
          and c.status in ('open', 'judging')
      )
    group by m.student_person_id
  ),
  ranked as (
    select m.id,
           row_number() over (partition by m.student_person_id
                              order by m.created_at, m.id) as rn_asc,
           row_number() over (partition by m.student_person_id
                              order by m.created_at desc, m.id desc) as rn_desc
    from public.media m
    join departed d on d.student_person_id = m.student_person_id
    where m.type = 'video' and m.retained = true
  ),
  pruned as (
    update public.media m
      set retained = false
    from ranked r
    where m.id = r.id and r.rn_asc > 1 and r.rn_desc > 1
    returning 1
  )
  select count(*) into v_count from pruned;

  insert into public.audit_log (actor_person_id, action, target_table, meta)
  values (null, 'cron_media_retention', 'media',
          jsonb_build_object('demoted', v_count));

  return v_count;
end;
$$;

revoke all on function public.run_media_retention() from public, anon, authenticated;

-- Run weekly on Sunday at 04:00.
select cron.schedule(
  'media-retention',
  '0 4 * * 0',
  $cron$ select public.run_media_retention(); $cron$
);
