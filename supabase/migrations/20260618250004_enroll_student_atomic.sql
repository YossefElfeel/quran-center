-- M5.3b review fix: atomic student enrollment (person + enrollment + optional
-- national id) in ONE transaction. Prevents an orphan student / duplicate-on-retry
-- when a national id is a duplicate — the whole enrollment rolls back.
create or replace function public.enroll_student(
  p_circle uuid,
  p_name text,
  p_gender text,
  p_national_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_person uuid;
begin
  if not (public.is_admin() or public.is_supervisor() or public.is_super_admin()) then
    raise exception 'غير مصرّح بتسجيل طالب' using errcode = '42501';
  end if;

  insert into public.person (full_name, gender, is_minor)
  values (p_name, p_gender::public.gender, true)
  returning id into v_person;

  insert into public.enrollment (student_person_id, circle_id, status)
  values (v_person, p_circle, 'active');

  if p_national_id is not null and length(trim(p_national_id)) > 0 then
    perform public.set_person_national_id(v_person, p_national_id);
  end if;

  return v_person;
end;
$$;

revoke all on function public.enroll_student(uuid, text, text, text) from public, anon;
grant execute on function public.enroll_student(uuid, text, text, text) to authenticated;
