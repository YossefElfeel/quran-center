-- RLS isolation regression suite (M8.2) — the gate for the private-schema move (M2.3).
--
-- Creates a throwaway scenario (2 circles/teachers, students/guardians, a girl student,
-- an admin, a complaint, a teacher rating, a girl's media), fabricates test auth users,
-- simulates each role via the JWT-claims + `set local role authenticated` pattern, and
-- asserts the isolation matrix:
--   - a teacher reads only their own circle's enrollments (teaches_circle)
--   - a teacher is BLIND to their own teacher_rating (manager-only)
--   - a guardian reads only their own child's enrollment (is_guardian_of)
--   - a girl's media is BLOCKED for her guardian without an active consent, and becomes
--     visible after consent (media_consent_ok / has_active_media_consent)
--   - complaints are visible to managers (is_admin) only
-- It ALWAYS rolls back (raises at the end). Success => "RLS OK ..."; any violation =>
-- "RLS FAIL: ...".
--
-- Run before AND after the M2.3 migration (RLS helpers -> private schema); the result
-- must stay "RLS OK". Run via the Supabase SQL editor / MCP execute_sql / `psql -f`.
do $$
declare
  v_curr uuid; v_level uuid; v_c1 uuid; v_c2 uuid;
  v_t1 uuid; v_t2 uuid; v_s1 uuid; v_s2 uuid; v_s3 uuid;
  v_g1 uuid; v_g2 uuid; v_g3 uuid; v_a1 uuid;
  v_enr1 uuid; v_portion uuid;
  v_uid_t1 uuid := gen_random_uuid();
  v_uid_g1 uuid := gen_random_uuid();
  v_uid_g3 uuid := gen_random_uuid();
  v_uid_a1 uuid := gen_random_uuid();
begin
  -- ---- setup (runs as the migration role; RLS bypassed) ----
  insert into public.curriculum (name) values ('RLS Curr') returning id into v_curr;
  insert into public.level (curriculum_id, ord, name) values (v_curr, 1, 'L') returning id into v_level;
  insert into public.person (full_name) values ('RLS T1') returning id into v_t1;
  insert into public.person (full_name) values ('RLS T2') returning id into v_t2;
  insert into public.person (full_name) values ('RLS S1') returning id into v_s1;
  insert into public.person (full_name) values ('RLS S2') returning id into v_s2;
  insert into public.person (full_name, gender) values ('RLS S3', 'female') returning id into v_s3;
  insert into public.person (full_name) values ('RLS G1') returning id into v_g1;
  insert into public.person (full_name) values ('RLS G2') returning id into v_g2;
  insert into public.person (full_name) values ('RLS G3') returning id into v_g3;
  insert into public.person (full_name) values ('RLS A1') returning id into v_a1;
  insert into public.circle (level_id, name, teacher_id) values (v_level, 'RLS C1', v_t1) returning id into v_c1;
  insert into public.circle (level_id, name, teacher_id) values (v_level, 'RLS C2', v_t2) returning id into v_c2;
  insert into public.enrollment (student_person_id, circle_id) values (v_s1, v_c1), (v_s2, v_c2);
  select id into v_enr1 from public.enrollment where student_person_id = v_s1;
  insert into public.portion (name, surah_start, ayah_start, surah_end, ayah_end)
    values ('RLS Portion', 1, 1, 1, 7) returning id into v_portion;
  insert into public.daily_tasmee (enrollment_id, portion_id, score, passed, idempotency_key, teacher_id)
    values (v_enr1, v_portion, 8, true, gen_random_uuid(), v_t1);
  insert into public.guardian_link (guardian_person_id, student_person_id) values (v_g1, v_s1), (v_g2, v_s2), (v_g3, v_s3);
  insert into public.role_assignment (person_id, role) values
    (v_t1, 'teacher'), (v_t2, 'teacher'), (v_g1, 'parent'), (v_g2, 'parent'), (v_g3, 'parent'), (v_a1, 'admin');
  insert into auth.users (id) values (v_uid_t1), (v_uid_g1), (v_uid_g3), (v_uid_a1);
  insert into public.app_user (auth_user_id, person_id) values
    (v_uid_t1, v_t1), (v_uid_g1, v_g1), (v_uid_g3, v_g3), (v_uid_a1, v_a1);
  insert into public.complaint (author_person_id, category, body, status) values (v_g1, 'other', 'RLS complaint', 'open');
  insert into public.teacher_rating (teacher_person_id, parent_person_id, period, stars)
    values (v_t1, v_g1, date_trunc('month', now())::date, 5);
  insert into public.media (student_person_id, type, storage_path) values (v_s3, 'video', 's3/test.mp4');

  -- ---- teacher T1: own circle only; no complaints; blind to own rating ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid_t1::text)::text, true);
  set local role authenticated;
  if (select count(*) from public.enrollment where circle_id = v_c1) <> 1 then raise exception 'RLS FAIL: teacher cannot read own circle'; end if;
  if (select count(*) from public.enrollment where circle_id = v_c2) <> 0 then raise exception 'RLS FAIL: teacher reads another circle'; end if;
  if (select count(*) from public.complaint where body = 'RLS complaint') <> 0 then raise exception 'RLS FAIL: non-manager reads complaints'; end if;
  if (select count(*) from public.teacher_rating where teacher_person_id = v_t1) <> 0 then raise exception 'RLS FAIL: teacher reads own rating'; end if;
  if (select count(*) from public.daily_tasmee where enrollment_id = v_enr1) <> 1 then raise exception 'RLS FAIL: teacher cannot read own tasmee'; end if;
  reset role;

  -- ---- guardian G1: own child only ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid_g1::text)::text, true);
  set local role authenticated;
  if (select count(*) from public.enrollment where student_person_id = v_s1) <> 1 then raise exception 'RLS FAIL: guardian cannot read own child'; end if;
  if (select count(*) from public.enrollment where student_person_id = v_s2) <> 0 then raise exception 'RLS FAIL: guardian reads another child'; end if;
  reset role;

  -- ---- girl's media: blocked without consent ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid_g3::text)::text, true);
  set local role authenticated;
  if (select count(*) from public.media where student_person_id = v_s3) <> 0 then raise exception 'RLS FAIL: girl media visible without consent'; end if;
  reset role;

  -- ---- grant consent -> girl's media becomes visible to her guardian ----
  insert into public.consent_record (student_person_id, scope, granted_by) values (v_s3, 'video', v_g3);
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid_g3::text)::text, true);
  set local role authenticated;
  if (select count(*) from public.media where student_person_id = v_s3) <> 1 then raise exception 'RLS FAIL: girl media hidden after consent'; end if;
  reset role;

  -- ---- admin A1: reads complaints + teacher ratings ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid_a1::text)::text, true);
  set local role authenticated;
  if (select count(*) from public.complaint where body = 'RLS complaint') <> 1 then raise exception 'RLS FAIL: admin cannot read complaints'; end if;
  if (select count(*) from public.teacher_rating where teacher_person_id = v_t1) <> 1 then raise exception 'RLS FAIL: admin cannot read teacher rating'; end if;
  reset role;

  -- ---- block kill-switch (M6): محظور/موقوف يفقد كل صلاحيات RLS ----
  -- teacher محظور: teaches_circle() بترجع false → مايقدرش يقرا حلقته.
  update public.person set blocked_at = now(), blocked_reason = 'test' where id = v_t1;
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid_t1::text)::text, true);
  set local role authenticated;
  if (select count(*) from public.enrollment where circle_id = v_c1) <> 0 then raise exception 'RLS FAIL: blocked teacher still reads own circle'; end if;
  if (select count(*) from public.daily_tasmee where enrollment_id = v_enr1) <> 0 then raise exception 'RLS FAIL: blocked teacher still reads own tasmee (teaches_enrollment)'; end if;
  reset role;

  -- admin محظور: has_role('admin') بترجع false → مايقدرش يقرا الشكاوى/التقييمات.
  update public.person set blocked_at = now(), blocked_reason = 'test' where id = v_a1;
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid_a1::text)::text, true);
  set local role authenticated;
  if (select count(*) from public.complaint where body = 'RLS complaint') <> 0 then raise exception 'RLS FAIL: blocked admin still reads complaints'; end if;
  if (select count(*) from public.teacher_rating where teacher_person_id = v_t1) <> 0 then raise exception 'RLS FAIL: blocked admin still reads teacher rating'; end if;
  reset role;

  -- guardian موقوف (deactivated): current_person_id()/is_guardian_of() → null/false.
  update public.person set deactivated_at = now() where id = v_g1;
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid_g1::text)::text, true);
  set local role authenticated;
  if (select count(*) from public.enrollment where student_person_id = v_s1) <> 0 then raise exception 'RLS FAIL: deactivated guardian still reads own child'; end if;
  reset role;

  raise exception 'RLS OK — teacher/guardian/admin + rating-blindness + girl-media-consent + block/deactivate kill-switch invariants held (rolled back)';
end $$;
