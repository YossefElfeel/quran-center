-- RLS isolation regression suite (M8.2) — the gate for the private-schema move (M2.3).
--
-- Creates a throwaway scenario (2 circles/teachers, 2 students/guardians, an admin, a
-- complaint), fabricates test auth users, simulates each role via the JWT-claims +
-- `set local role authenticated` pattern, and asserts the core isolation matrix:
--   - a teacher reads only their own circle's enrollments (teaches_circle)
--   - a guardian reads only their own child's enrollment (is_guardian_of)
--   - complaints are visible to managers (is_admin) only, not to other roles
-- It ALWAYS rolls back (raises at the end). Success => "RLS OK ..."; any violation =>
-- "RLS FAIL: ...".
--
-- Run before AND after the M2.3 migration (moving RLS helper functions to a private
-- schema); the result must stay "RLS OK". Run via the Supabase SQL editor / MCP
-- execute_sql / `psql -f`.
do $$
declare
  v_curr uuid; v_level uuid; v_c1 uuid; v_c2 uuid;
  v_t1 uuid; v_t2 uuid; v_s1 uuid; v_s2 uuid; v_g1 uuid; v_g2 uuid; v_a1 uuid;
  v_uid_t1 uuid := gen_random_uuid();
  v_uid_g1 uuid := gen_random_uuid();
  v_uid_a1 uuid := gen_random_uuid();
begin
  -- ---- setup (runs as the migration role; RLS bypassed) ----
  insert into public.curriculum (name) values ('RLS Curr') returning id into v_curr;
  insert into public.level (curriculum_id, ord, name) values (v_curr, 1, 'L') returning id into v_level;
  insert into public.person (full_name) values ('RLS T1') returning id into v_t1;
  insert into public.person (full_name) values ('RLS T2') returning id into v_t2;
  insert into public.person (full_name) values ('RLS S1') returning id into v_s1;
  insert into public.person (full_name) values ('RLS S2') returning id into v_s2;
  insert into public.person (full_name) values ('RLS G1') returning id into v_g1;
  insert into public.person (full_name) values ('RLS G2') returning id into v_g2;
  insert into public.person (full_name) values ('RLS A1') returning id into v_a1;
  insert into public.circle (level_id, name, teacher_id) values (v_level, 'RLS C1', v_t1) returning id into v_c1;
  insert into public.circle (level_id, name, teacher_id) values (v_level, 'RLS C2', v_t2) returning id into v_c2;
  insert into public.enrollment (student_person_id, circle_id) values (v_s1, v_c1), (v_s2, v_c2);
  insert into public.guardian_link (guardian_person_id, student_person_id) values (v_g1, v_s1), (v_g2, v_s2);
  insert into public.role_assignment (person_id, role) values
    (v_t1, 'teacher'), (v_t2, 'teacher'), (v_g1, 'parent'), (v_g2, 'parent'), (v_a1, 'admin');
  insert into auth.users (id) values (v_uid_t1), (v_uid_g1), (v_uid_a1);
  insert into public.app_user (auth_user_id, person_id) values
    (v_uid_t1, v_t1), (v_uid_g1, v_g1), (v_uid_a1, v_a1);
  insert into public.complaint (author_person_id, category, body, status)
    values (v_g1, 'other', 'RLS complaint', 'open');

  -- ---- teacher T1: own circle only; no complaints ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid_t1::text)::text, true);
  set local role authenticated;
  if (select count(*) from public.enrollment where circle_id = v_c1) <> 1 then
    raise exception 'RLS FAIL: teacher cannot read own circle';
  end if;
  if (select count(*) from public.enrollment where circle_id = v_c2) <> 0 then
    raise exception 'RLS FAIL: teacher reads another circle';
  end if;
  if (select count(*) from public.complaint where body = 'RLS complaint') <> 0 then
    raise exception 'RLS FAIL: non-manager reads complaints';
  end if;
  reset role;

  -- ---- guardian G1: own child only ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid_g1::text)::text, true);
  set local role authenticated;
  if (select count(*) from public.enrollment where student_person_id = v_s1) <> 1 then
    raise exception 'RLS FAIL: guardian cannot read own child';
  end if;
  if (select count(*) from public.enrollment where student_person_id = v_s2) <> 0 then
    raise exception 'RLS FAIL: guardian reads another child';
  end if;
  reset role;

  -- ---- admin A1: reads complaints ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid_a1::text)::text, true);
  set local role authenticated;
  if (select count(*) from public.complaint where body = 'RLS complaint') <> 1 then
    raise exception 'RLS FAIL: admin cannot read complaints';
  end if;
  reset role;

  raise exception 'RLS OK — teacher/guardian/admin isolation invariants held (rolled back)';
end $$;
