-- M4.1: monthly close. Runs on the 1st at 02:00 and closes the PREVIOUS calendar
-- month. For every student with an active enrollment it generates exactly one
-- monthly_student_evaluation (idempotent on (student, month)):
--   * 'draft'  when the teacher recorded any tasmee/attendance that month;
--   * 'missed' when nothing was recorded (the teacher didn't submit) -> escalated.
-- It also nominates a monthly_top_student per circle (highest tasmee average),
-- notifies the guardians of newly-evaluated students that the monthly progress
-- card is ready, escalates 'missed' evaluations to supervisors/admins, and writes
-- a system manifest to audit_log (actor = NULL = system).
--
-- The subscription "cycle" is calendar-derived (period_month on each payment, no
-- stored cycle row), and overdue dues are handled by notify-overdue-subscriptions,
-- so there is nothing to materialise here for the new month.
--
-- security definer + search_path='' + revoked from API roles (system-only).
-- cron.schedule upserts by name, so re-running this migration is safe. The worker
-- takes an optional p_month so it can be smoke-tested against a fixed month.

create or replace function public.run_monthly_close(p_month date default null)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_month date := coalesce(p_month, (date_trunc('month', now()) - interval '1 month')::date);
  v_next  date := (v_month + interval '1 month')::date;
  v_new      uuid[];
  v_missed   uuid[];
  v_evals    integer := 0;
  v_missed_n integer := 0;
  v_tops     integer := 0;
  v_cards    integer := 0;
begin
  -- 1) One evaluation per student with an active enrollment, computed from the
  --    month's recitation (avg score), attendance (present+late / total) and
  --    parent-visible behavioural notes. Idempotent via the unique (student, month).
  with act as (
    select distinct e.student_person_id
    from public.enrollment e
    where e.status = 'active'
  ),
  tas as (
    select e.student_person_id,
           avg(dt.score)::numeric(4, 2) as tasmee_avg,
           count(*) as n
    from public.enrollment e
    join public.daily_tasmee dt on dt.enrollment_id = e.id
    where e.status = 'active'
      and dt.attempt_date >= v_month and dt.attempt_date < v_next
    group by e.student_person_id
  ),
  att as (
    select e.student_person_id,
           (count(*) filter (where a.status in ('present', 'late')))::numeric
             / nullif(count(*), 0) as attendance_rate,
           count(*) as n
    from public.enrollment e
    join public.attendance a on a.enrollment_id = e.id
    join public.circle_session cs on cs.id = a.session_id
    where e.status = 'active'
      and cs.session_date >= v_month and cs.session_date < v_next
    group by e.student_person_id
  ),
  beh as (
    select bn.student_person_id,
           string_agg(bn.text, ' | ' order by bn.created_at) as behavior
    from public.behavioral_note bn
    where bn.created_at >= v_month and bn.created_at < v_next
      and bn.visibility = 'parent'
    group by bn.student_person_id
  ),
  ins as (
    insert into public.monthly_student_evaluation
      (student_person_id, month, status, tasmee_avg, attendance_rate, behavior)
    select a.student_person_id, v_month,
           case when coalesce(t.n, 0) > 0 or coalesce(ar.n, 0) > 0
                then 'draft' else 'missed' end::public.monthly_eval_status,
           t.tasmee_avg,
           round(ar.attendance_rate, 3),
           b.behavior
    from act a
    left join tas t  on t.student_person_id = a.student_person_id
    left join att ar on ar.student_person_id = a.student_person_id
    left join beh b  on b.student_person_id = a.student_person_id
    on conflict (student_person_id, month) do nothing
    returning student_person_id, status
  )
  select coalesce(array_agg(student_person_id), '{}'::uuid[]),
         coalesce(array_agg(student_person_id) filter (where status = 'missed'), '{}'::uuid[])
    into v_new, v_missed
  from ins;

  v_evals    := coalesce(array_length(v_new, 1), 0);
  v_missed_n := coalesce(array_length(v_missed, 1), 0);

  -- 2) Top student per circle = highest tasmee average that month. Idempotent.
  with ranked as (
    select e.circle_id, e.student_person_id,
           row_number() over (
             partition by e.circle_id
             order by avg(dt.score) desc, e.student_person_id
           ) as rn
    from public.enrollment e
    join public.daily_tasmee dt on dt.enrollment_id = e.id
    where e.status = 'active'
      and dt.attempt_date >= v_month and dt.attempt_date < v_next
    group by e.circle_id, e.student_person_id
  ),
  ins_top as (
    insert into public.monthly_top_student (circle_id, month, student_person_id, reason)
    select circle_id, v_month, student_person_id, 'الأعلى في متوسّط التسميع للشهر'
    from ranked where rn = 1
    on conflict (circle_id, month) do nothing
    returning 1
  )
  select count(*) into v_tops from ins_top;

  -- 3) Notify guardians of NEWLY-evaluated students that the progress card is ready.
  with cards as (
    insert into public.notification (recipient_person_id, type, title, body)
    select gl.guardian_person_id, 'progress_card',
           'بطاقة التقدّم الشهرية جاهزة',
           'بطاقة تقدّم ابنك للشهر اللي فات بقت متاحة في التطبيق.'
    from public.guardian_link gl
    where gl.student_person_id = any (v_new)
    returning 1
  )
  select count(*) into v_cards from cards;

  -- 4) Escalate 'missed' evaluations (teacher didn't submit) to managers.
  if v_missed_n > 0 then
    insert into public.notification (recipient_person_id, type, title, body)
    select ra.person_id, 'monthly_eval_missed', 'تقييمات شهرية ناقصة',
           'فيه طلبة الشهر اللي فات من غير تسميع/حضور مسجّل. لو سمحت راجع الحلقات وكمّل تقييماتهم.'
    from public.role_assignment ra
    where ra.role in ('supervisor', 'admin', 'super_admin');
  end if;

  -- 5) System manifest.
  insert into public.audit_log (actor_person_id, action, target_table, meta)
  values (null, 'cron_monthly_close', 'monthly_student_evaluation',
          jsonb_build_object('month', v_month, 'evaluations', v_evals,
                             'missed', v_missed_n, 'top_students', v_tops,
                             'progress_cards', v_cards));

  return v_evals;
end;
$$;

revoke all on function public.run_monthly_close(date) from public, anon, authenticated;

-- Run on the 1st of every month at 02:00.
select cron.schedule(
  'monthly-close',
  '0 2 1 * *',
  $cron$ select public.run_monthly_close(); $cron$
);
