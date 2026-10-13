-- UX review fixes (M1, M3, monthly_eval_missed).
-- Write-only migration: replaces two functions and adds one read-only RPC. No data changes.

-- M1: changing a guardian's household now really moves the guardian. The old
-- membership is removed and the new one inserted in the same transaction
-- (household_member has unique(person_id), so a guardian belongs to one household).
-- Previously the insert used "on conflict do nothing" and silently kept the old household.
create or replace function public.update_guardian_details(p_guardian_id uuid,p_student_id uuid,p_name text,p_phone text,p_relation text,p_household_id uuid default null,p_new_household_name text default null)
returns void language plpgsql security definer set search_path='' as $$
declare v_current uuid; v_target uuid;
begin
  if auth.uid() is null or not (private.is_admin() or private.is_super_admin()) then raise exception 'admin required' using errcode='42501'; end if;
  if coalesce(length(btrim(p_name)),0)<2 or p_relation not in ('father','mother','other') or (coalesce(p_phone,'')<>'' and p_phone !~ '^\+?[0-9]{10,15}$') then raise exception 'invalid details' using errcode='22023'; end if;
  if not exists(select 1 from public.guardian_link where guardian_person_id=p_guardian_id and student_person_id=p_student_id) then raise exception 'guardian link missing' using errcode='22023'; end if;
  -- Lock the current membership so two concurrent edits cannot both move the guardian.
  select household_id into v_current from public.household_member where person_id=p_guardian_id for update;
  if p_household_id is not null then
    if not exists(select 1 from public.household where id=p_household_id) then raise exception 'household missing' using errcode='22023'; end if;
    v_target:=p_household_id;
  elsif coalesce(btrim(p_new_household_name),'')<>'' then
    insert into public.household(name) values(btrim(p_new_household_name)) returning id into v_target;
  elsif v_current is not null then
    v_target:=v_current;
  else
    raise exception 'household required' using errcode='22023';
  end if;
  update public.person set full_name=btrim(p_name),phone=nullif(p_phone,'') where id=p_guardian_id;
  update public.guardian_link set relation=p_relation where guardian_person_id=p_guardian_id and student_person_id=p_student_id;
  if v_current is distinct from v_target then
    if v_current is not null then
      delete from public.household_member where person_id=p_guardian_id and household_id=v_current;
    end if;
    insert into public.household_member(household_id,person_id,role) values(v_target,p_guardian_id,'guardian');
  end if;
  if not exists(select 1 from public.household_member where person_id=p_guardian_id and household_id=v_target) then
    raise exception 'household move failed' using errcode='P0001';
  end if;
end $$;
revoke all on function public.update_guardian_details(uuid,uuid,text,text,text,uuid,text) from public,anon;
grant execute on function public.update_guardian_details(uuid,uuid,text,text,text,uuid,text) to authenticated;

-- M3: RLS denials during a freeze surface as a generic 42501. Clients call this after a
-- 42501 on session open/close/sync to tell the user why. Super admins are exempt from the
-- freeze policies, so they always get null.
create or replace function public.session_writes_blocked() returns text
language sql stable security definer set search_path='' as $$
  select case
    when private.is_super_admin() then null
    when private.flag_enabled('freeze_sessions') then 'freeze_sessions'
    when private.flag_enabled('maintenance_mode') then 'maintenance_mode'
  end;
$$;
revoke all on function public.session_writes_blocked() from public,anon;
grant execute on function public.session_writes_blocked() to authenticated;

-- monthly_eval_missed: also notify each affected circle's teacher (the person who has to act),
-- with route_data {circle_id, month} so the app opens that circle's monthly evaluation.
-- Staff keep one notification each (deduplicated across roles), now carrying {month}.
-- Idempotency is unchanged: notifications are only sent for evaluations inserted by this run.
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
  -- 1) One evaluation per student with an active enrollment. Idempotent via unique (student, month).
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

  -- 4) Escalate 'missed' evaluations: each affected circle's teacher, then managers.
  if v_missed_n > 0 then
    insert into public.notification (recipient_person_id, type, title, body, route_data)
    select c.teacher_id, 'monthly_eval_missed', 'تقييمات شهرية ناقصة في حلقتك',
           format('فيه %s طالب في حلقة "%s" من غير تسميع/حضور مسجّل الشهر اللي فات. لو سمحت كمّل تقييماتهم.',
                  count(distinct e.student_person_id), c.name),
           jsonb_build_object('circle_id', c.id, 'month', v_month)
    from public.enrollment e
    join public.circle c on c.id = e.circle_id
    where e.status = 'active'
      and e.student_person_id = any (v_missed)
      and c.teacher_id is not null
    group by c.id, c.teacher_id, c.name;

    insert into public.notification (recipient_person_id, type, title, body, route_data)
    select ra.person_id, 'monthly_eval_missed', 'تقييمات شهرية ناقصة',
           'فيه طلبة الشهر اللي فات من غير تسميع/حضور مسجّل. لو سمحت راجع الحلقات وكمّل تقييماتهم.',
           jsonb_build_object('month', v_month)
    from (select distinct person_id from public.role_assignment
          where role in ('supervisor', 'admin', 'super_admin')) ra;
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
