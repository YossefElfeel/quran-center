-- M1.9 (data): aggregates the monthly circle report for the print/preview screen.
-- security invoker => RLS applies to the caller (same approach as circle_pass_rates);
-- supervisors/admins can read enrollment/attendance/daily_tasmee/circle_session/person
-- so the aggregate is complete for them. Returns one jsonb object:
--   { active_students, avg_attendance_rate (0..1), pass_rate (0..1),
--     top_student_name, portions:[{label, passed, total}] }
-- p_month is any date inside the target month (the function trims to the month).

create or replace function public.monthly_circle_report(p_circle uuid, p_month date)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  with bounds as (
    select date_trunc('month', p_month)::date as m_start,
           (date_trunc('month', p_month) + interval '1 month')::date as m_end
  ),
  active as (
    select e.id, e.student_person_id
    from public.enrollment e
    where e.circle_id = p_circle and e.status = 'active'
  ),
  att as (
    select count(*) filter (where a.status in ('present', 'late'))::numeric
             / nullif(count(*), 0) as rate
    from public.attendance a
    join active ac on ac.id = a.enrollment_id
    join public.circle_session cs on cs.id = a.session_id, bounds b
    where cs.session_date >= b.m_start and cs.session_date < b.m_end
  ),
  tas as (
    select count(*) filter (where dt.passed)::numeric
             / nullif(count(*), 0) as rate
    from public.daily_tasmee dt
    join active ac on ac.id = dt.enrollment_id, bounds b
    where dt.attempt_date >= b.m_start and dt.attempt_date < b.m_end
  ),
  top as (
    select p.full_name
    from public.daily_tasmee dt
    join active ac on ac.id = dt.enrollment_id
    join public.person p on p.id = ac.student_person_id, bounds b
    where dt.attempt_date >= b.m_start and dt.attempt_date < b.m_end
    group by p.id, p.full_name
    order by avg(dt.score) desc, p.full_name
    limit 1
  ),
  portions as (
    select po.name as label,
           count(*) filter (where dt.passed) as passed,
           count(*) as total
    from public.daily_tasmee dt
    join active ac on ac.id = dt.enrollment_id
    join public.portion po on po.id = dt.portion_id, bounds b
    where dt.attempt_date >= b.m_start and dt.attempt_date < b.m_end
    group by po.id, po.name
    order by po.name
  )
  select jsonb_build_object(
    'active_students', (select count(*) from active),
    'avg_attendance_rate', coalesce((select rate from att), 0),
    'pass_rate', coalesce((select rate from tas), 0),
    'top_student_name', coalesce((select full_name from top), ''),
    'portions', coalesce(
      (select jsonb_agg(jsonb_build_object(
                'label', label, 'passed', passed, 'total', total))
       from portions), '[]'::jsonb)
  );
$$;

revoke all on function public.monthly_circle_report(uuid, date) from public, anon;
grant execute on function public.monthly_circle_report(uuid, date) to authenticated;
