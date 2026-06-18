-- Engine flow integration test (M8.2c) — exercises the authoritative server-side
-- memorization engine end-to-end on a real schema copy: enroll 3 students, set the
-- circle's current portion, then record_tasmee for each and assert the outcomes.
--
-- Asserts: passing scores -> ledger 'passed', failing -> 'failed_retry'; 2 of 3
-- passed (the >50% group-advance condition); every attempt stored in daily_tasmee;
-- and idempotent replay (same idempotency_key) neither changes the ledger nor
-- duplicates an attempt. Always rolls back (raises at the end).
-- Success => "ENGINE OK ..."; any violation => "ENGINE FAIL: ...".
-- Run via the Supabase SQL editor / MCP execute_sql / `psql -f`.
do $$
declare
  v_curr uuid; v_level uuid; v_circle uuid; v_teacher uuid;
  v_s1 uuid; v_s2 uuid; v_s3 uuid; v_e1 uuid; v_e2 uuid; v_e3 uuid;
  v_portion uuid; v_state public.ledger_state; v_passed int; v_attempts int;
  v_key uuid := gen_random_uuid();
begin
  insert into public.curriculum (name) values ('ENG Curr') returning id into v_curr;
  insert into public.level (curriculum_id, ord, name) values (v_curr, 1, 'L') returning id into v_level;
  insert into public.person (full_name) values ('ENG T') returning id into v_teacher;
  insert into public.person (full_name) values ('ENG S1') returning id into v_s1;
  insert into public.person (full_name) values ('ENG S2') returning id into v_s2;
  insert into public.person (full_name) values ('ENG S3') returning id into v_s3;
  insert into public.circle (level_id, name, teacher_id) values (v_level, 'ENG C', v_teacher) returning id into v_circle;
  insert into public.enrollment (student_person_id, circle_id) values (v_s1, v_circle) returning id into v_e1;
  insert into public.enrollment (student_person_id, circle_id) values (v_s2, v_circle) returning id into v_e2;
  insert into public.enrollment (student_person_id, circle_id) values (v_s3, v_circle) returning id into v_e3;
  insert into public.portion (name, surah_start, ayah_start, surah_end, ayah_end)
    values ('ENG P', 78, 1, 78, 40) returning id into v_portion;
  insert into public.group_portion_cycle (circle_id, portion_id, ord, active_at_open)
    values (v_circle, v_portion, 1, 3);

  -- s1 passes (key reused later for idempotency), s2 passes, s3 fails (threshold 7)
  v_state := public.record_tasmee(v_e1, v_s1, v_portion, 8::smallint, true, v_key);
  if v_state <> 'passed' then raise exception 'ENGINE FAIL: s1 expected passed, got %', v_state; end if;
  v_state := public.record_tasmee(v_e2, v_s2, v_portion, 9::smallint, true, gen_random_uuid());
  if v_state <> 'passed' then raise exception 'ENGINE FAIL: s2 expected passed, got %', v_state; end if;
  v_state := public.record_tasmee(v_e3, v_s3, v_portion, 4::smallint, false, gen_random_uuid());
  if v_state <> 'failed_retry' then raise exception 'ENGINE FAIL: s3 expected failed_retry, got %', v_state; end if;

  -- 2 of 3 passed (the >50% advance condition)
  select count(*) into v_passed from public.portion_ledger_entry where portion_id = v_portion and state = 'passed';
  if v_passed <> 2 then raise exception 'ENGINE FAIL: expected 2 passed, got %', v_passed; end if;

  -- every attempt stored (3)
  select count(*) into v_attempts from public.daily_tasmee where portion_id = v_portion;
  if v_attempts <> 3 then raise exception 'ENGINE FAIL: expected 3 attempts, got %', v_attempts; end if;

  -- idempotency: replay s1 with the SAME key -> no new attempt, state still passed
  v_state := public.record_tasmee(v_e1, v_s1, v_portion, 8::smallint, true, v_key);
  if v_state <> 'passed' then raise exception 'ENGINE FAIL: idempotent replay changed state to %', v_state; end if;
  select count(*) into v_attempts from public.daily_tasmee where portion_id = v_portion;
  if v_attempts <> 3 then raise exception 'ENGINE FAIL: idempotent replay duplicated attempt (now %)', v_attempts; end if;

  raise exception 'ENGINE OK — 2/3 passed + 1 debt, all attempts stored, idempotent replay safe (rolled back)';
end $$;
