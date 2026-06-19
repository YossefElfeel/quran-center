-- M5.2: auto-accrue the student journey ("teacher credit").
-- (a) When a portion ledger entry first reaches 'passed', add that portion's page
--     count to the student's OPEN journey segment for their current active circle
--     (creating it if none). Pages sum per distinct portion (each credited once);
--     ajza = pages*30/604. from_point/to_point use the portion name as a label.
-- (b) When an enrollment ends for a circle (transferred/dropped/graduated), close the
--     open segment so the teacher credit is frozen at that point.

create or replace function public.accrue_journey_on_ledger_pass()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_circle uuid;
  v_teacher uuid;
  v_ss smallint; v_sa smallint; v_se smallint; v_ea smallint; v_name text;
  v_pages int;
  v_seg uuid;
begin
  if new.state <> 'passed' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.state = 'passed' then
    return new;  -- already credited; avoid double count on re-pass
  end if;

  -- current circle + its teacher (a student has at most one active enrollment)
  select e.circle_id, c.teacher_id
    into v_circle, v_teacher
  from public.enrollment e
  join public.circle c on c.id = e.circle_id
  where e.student_person_id = new.student_person_id and e.status = 'active'
  limit 1;
  if v_circle is null then
    return new;
  end if;

  select surah_start, ayah_start, surah_end, ayah_end, name
    into v_ss, v_sa, v_se, v_ea, v_name
  from public.portion where id = new.portion_id;
  if v_ss is null then
    return new;
  end if;

  select pages into v_pages
  from public.portion_to_ajza_pages(v_ss, v_sa, v_se, v_ea);
  v_pages := coalesce(v_pages, 0);

  select id into v_seg
  from public.student_journey_segment
  where student_person_id = new.student_person_id and circle_id = v_circle
    and ended_at is null
  limit 1;

  if v_seg is null then
    insert into public.student_journey_segment
      (student_person_id, circle_id, teacher_id, from_point, to_point, pages, ajza)
    values
      (new.student_person_id, v_circle, v_teacher, v_name, v_name,
       v_pages, round(v_pages * 30.0 / 604.0, 2));
  else
    update public.student_journey_segment
      set pages = pages + v_pages,
          ajza = round((pages + v_pages) * 30.0 / 604.0, 2),
          to_point = v_name,
          teacher_id = coalesce(teacher_id, v_teacher)
    where id = v_seg;
  end if;

  return new;
end;
$$;

create trigger ledger_journey_accrual
  after insert or update of state on public.portion_ledger_entry
  for each row execute function public.accrue_journey_on_ledger_pass();

create or replace function public.close_journey_on_enrollment_end()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status in ('transferred', 'dropped', 'graduated')
     and old.status is distinct from new.status then
    update public.student_journey_segment
      set ended_at = now()
    where student_person_id = new.student_person_id
      and circle_id = new.circle_id
      and ended_at is null;
  end if;
  return new;
end;
$$;

create trigger enrollment_close_journey
  after update of status on public.enrollment
  for each row execute function public.close_journey_on_enrollment_end();
