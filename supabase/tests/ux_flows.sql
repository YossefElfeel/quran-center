-- UX release regression suite. Run only after all UX migrations (through 20261013120000) have committed.
-- All fixtures, test identities, notifications and payments roll back.
-- Success raises "UX OK"; a failed invariant raises "UX FAIL".
do $$
declare
  v_admin uuid; v_admin_uid uuid := gen_random_uuid();
  v_teacher uuid; v_student uuid; v_curr uuid; v_level uuid; v_circle uuid; v_new_circle uuid; v_new_teacher uuid;
  v_guardian uuid; v_guardian_uid uuid := gen_random_uuid(); v_household uuid;
  v_payment uuid; v_eval uuid; v_dev uuid; v_session uuid;
  v_competition uuid; v_public_application uuid; v_duplicate_application uuid;
  v_public_phone text := '999' || lpad(floor(random()*1000000000)::bigint::text,9,'0');
  v_month date := date_trunc('month', now() at time zone 'Africa/Cairo')::date;
  v_old_month date := '2001-01-01';
  v_moved_household uuid;
begin
  insert into public.person(full_name,is_minor) values ('UX Admin',false) returning id into v_admin;
  insert into public.role_assignment(person_id,role) values(v_admin,'admin');
  insert into auth.users(id) values(v_admin_uid);
  insert into public.app_user(auth_user_id,person_id) values(v_admin_uid,v_admin);
  insert into public.person(full_name,is_minor) values('UX Teacher',false) returning id into v_teacher;
  insert into public.role_assignment(person_id,role) values(v_teacher,'teacher');
  insert into public.person(full_name,is_minor) values('UX Student',true) returning id into v_student;
  insert into public.curriculum(name) values('UX Curriculum') returning id into v_curr;
  insert into public.level(curriculum_id,ord,name) values(v_curr,1,'UX Level') returning id into v_level;
  insert into public.circle(level_id,name,teacher_id) values(v_level,'UX Circle',v_teacher) returning id into v_circle;
  insert into public.enrollment(student_person_id,circle_id) values(v_student,v_circle);

  perform set_config('request.jwt.claims',json_build_object('sub',v_admin_uid::text)::text,true);
  set local role authenticated;
  v_guardian := public.create_guardian_with_household('UX Guardian',v_student,'father',null,'UX Family','201000000099');
  reset role;
  select household_id into v_household from public.household_member where person_id=v_guardian;
  if v_household is null or not exists(select 1 from public.guardian_link where guardian_person_id=v_guardian and student_person_id=v_student)
    or not exists(select 1 from public.person where id=v_guardian and phone='201000000099') then
    raise exception 'UX FAIL: guardian identity, child, phone or household missing';
  end if;

  insert into public.subscription_payment(household_id,period_month,amount,method)
    values(v_household,v_month,25,'cash') returning id into v_payment;
  begin
    insert into public.subscription_payment(household_id,period_month,amount,method) values(v_household,v_month,25,'cash');
    raise exception 'UX FAIL: duplicate payment accepted';
  exception when unique_violation then null;
  end;
  update public.subscription_payment set voided=true,void_reason='UX test' where id=v_payment;
  insert into public.subscription_payment(household_id,period_month,amount,method) values(v_household,v_month,25,'instapay');

  -- This validates linkage in the database; live invite-user/generateLink is a separate check.
  insert into auth.users(id) values(v_guardian_uid);
  insert into public.app_user(auth_user_id,person_id) values(v_guardian_uid,v_guardian);
  perform set_config('request.jwt.claims',json_build_object('sub',v_guardian_uid::text)::text,true);
  set local role authenticated;
  if private.current_person_id() <> v_guardian or not public.my_subscription_active() then
    raise exception 'UX FAIL: guardian login not linked to paid household';
  end if;
  reset role;

  insert into public.monthly_student_evaluation(student_person_id,month,status,evaluator_teacher_id,summary)
    values(v_student,v_month,'submitted',v_teacher,'UX summary') returning id into v_eval;
  insert into public.teacher_development(teacher_person_id,month,status,memorization_progress)
    values(v_teacher,v_month,'submitted','UX progress') returning id into v_dev;
  -- Moving a student must not redirect a returned evaluation to another teacher's circle.
  update public.enrollment set status='transferred',left_at=now() where student_person_id=v_student;
  insert into public.person(full_name,is_minor) values('UX New Teacher',false) returning id into v_new_teacher;
  insert into public.role_assignment(person_id,role) values(v_new_teacher,'teacher');
  insert into public.circle(level_id,name,teacher_id) values(v_level,'UX New Circle',v_new_teacher) returning id into v_new_circle;
  insert into public.enrollment(student_person_id,circle_id) values(v_student,v_new_circle);
  perform set_config('request.jwt.claims',json_build_object('sub',v_admin_uid::text)::text,true);
  set local role authenticated;
  begin
    update public.monthly_student_evaluation set status='returned',return_reason='' where id=v_eval;
    raise exception 'UX FAIL: empty return reason accepted';
  exception when invalid_parameter_value then null;
  end;
  update public.monthly_student_evaluation set status='returned',return_reason='UX correction' where id=v_eval;
  update public.teacher_development set status='returned',return_reason='UX correction' where id=v_dev;
  reset role;
  if (select count(*) from public.notification where recipient_person_id=v_teacher and type in ('monthly_eval_returned','development_returned')) <> 2 then
    raise exception 'UX FAIL: returned notifications missing';
  end if;
  if not exists(select 1 from public.notification where recipient_person_id=v_teacher and type='monthly_eval_returned'
    and route_data->>'circle_id'=v_circle::text and route_data->>'month'=v_month::text) then
    raise exception 'UX FAIL: return destination lost circle or month';
  end if;

  insert into public.circle_session(circle_id,status,session_date,opened_by)
    values(v_circle,'open',(now() at time zone 'Africa/Cairo')::date,v_teacher) returning id into v_session;
  set local role authenticated;
  perform public.close_session_with_plan(v_session,null::jsonb,null::uuid);
  perform public.close_session_with_plan(v_session,null::jsonb,null::uuid);
  if public.today_session_status(v_circle)->>'status' <> 'closed' then
    raise exception 'UX FAIL: closed today session not retained';
  end if;
  reset role;
  insert into public.competition(name,status,deadline)
    values('UX Public Competition','open',now()+interval '1 day') returning id into v_competition;
  if has_function_privilege('authenticated','public.submit_public_competition_application(uuid,text,text,text,text,boolean,uuid)','execute')
    or has_function_privilege('anon','public.submit_public_competition_application(uuid,text,text,text,text,boolean,uuid)','execute') then
    raise exception 'UX FAIL: public submission RPC exposed outside trusted Edge role';
  end if;
  set local role service_role;
  v_public_application := public.submit_public_competition_application(
    v_competition,'UX Applicant',v_public_phone,v_public_phone,null,true,null);
  v_duplicate_application := public.submit_public_competition_application(
    v_competition,'UX Applicant',v_public_phone,v_public_phone,null,true,null);
  reset role;
  if v_public_application is null or v_public_application <> v_duplicate_application
    or (select count(*) from public.competition_application where competition_id=v_competition) <> 1 then
    raise exception 'UX FAIL: public duplicate submission did not retain one reference';
  end if;
  begin
    insert into public.public_registration(name,phone,normalized_phone,consent_ack)
      values('UX Duplicate',v_public_phone,v_public_phone,true);
    raise exception 'UX FAIL: duplicate normalized phone accepted';
  exception when unique_violation then null;
  end;
  begin
    insert into public.competition_application(competition_id,origin,public_registration_id)
      select competition_id,origin,public_registration_id
      from public.competition_application where id=v_public_application;
    raise exception 'UX FAIL: duplicate public application accepted';
  exception when unique_violation then null;
  end;
  update public.competition set deadline=now()-interval '1 minute' where id=v_competition;
  set local role service_role;
  begin
    perform public.submit_public_competition_application(
      v_competition,'UX Applicant',v_public_phone,v_public_phone,null,true,null);
    raise exception 'UX FAIL: expired competition accepted a submission';
  exception when invalid_parameter_value then null;
  end;
  reset role;

  -- M1: editing a guardian's household moves the membership instead of silently keeping the old one.
  insert into public.household(name) values('UX Moved Family') returning id into v_moved_household;
  perform set_config('request.jwt.claims',json_build_object('sub',v_admin_uid::text)::text,true);
  set local role authenticated;
  perform public.update_guardian_details(v_guardian,v_student,'UX Guardian','201000000099','mother',v_moved_household,null);
  reset role;
  if (select count(*) from public.household_member where person_id=v_guardian) <> 1
    or not exists(select 1 from public.household_member where person_id=v_guardian and household_id=v_moved_household)
    or exists(select 1 from public.household_member where person_id=v_guardian and household_id=v_household)
    or (select relation::text from public.guardian_link where guardian_person_id=v_guardian and student_person_id=v_student) <> 'mother' then
    raise exception 'UX FAIL: guardian household move did not take effect';
  end if;
  set local role authenticated;
  perform public.update_guardian_details(v_guardian,v_student,'UX Guardian','201000000099','mother',null,'UX Brand New Family');
  reset role;
  if (select h.name from public.household_member hm join public.household h on h.id=hm.household_id where hm.person_id=v_guardian) <> 'UX Brand New Family'
    or (select count(*) from public.household_member where person_id=v_guardian) <> 1 then
    raise exception 'UX FAIL: guardian move to a new household did not take effect';
  end if;

  -- M3: session_writes_blocked() names the active freeze, is null otherwise, and is not exposed to anon.
  if has_function_privilege('anon','public.session_writes_blocked()','execute')
    or not has_function_privilege('authenticated','public.session_writes_blocked()','execute') then
    raise exception 'UX FAIL: session_writes_blocked grants are wrong';
  end if;
  insert into public.feature_flag(key,enabled) values('freeze_sessions',false),('maintenance_mode',false)
    on conflict (key) do update set enabled=false;
  set local role authenticated;
  if public.session_writes_blocked() is not null then raise exception 'UX FAIL: writes reported blocked with no flag on'; end if;
  reset role;
  update public.feature_flag set enabled=true where key='maintenance_mode';
  set local role authenticated;
  if public.session_writes_blocked() is distinct from 'maintenance_mode' then raise exception 'UX FAIL: maintenance mode not reported'; end if;
  reset role;
  update public.feature_flag set enabled=true where key='freeze_sessions';
  set local role authenticated;
  if public.session_writes_blocked() is distinct from 'freeze_sessions' then raise exception 'UX FAIL: session freeze not reported'; end if;
  reset role;
  update public.feature_flag set enabled=false where key in ('freeze_sessions','maintenance_mode');

  -- Monthly close: a missed evaluation also reaches the circle's teacher with the circle and month.
  perform public.run_monthly_close(v_old_month);
  if not exists(select 1 from public.notification where recipient_person_id=v_new_teacher and type='monthly_eval_missed'
    and route_data->>'circle_id'=v_new_circle::text and route_data->>'month'=v_old_month::text) then
    raise exception 'UX FAIL: missed evaluation did not notify the circle teacher';
  end if;
  perform public.run_monthly_close(v_old_month);
  if (select count(*) from public.notification where recipient_person_id=v_new_teacher and type='monthly_eval_missed'
    and route_data->>'month'=v_old_month::text) <> 1 then
    raise exception 'UX FAIL: monthly close re-run duplicated teacher notifications';
  end if;
  raise exception 'UX OK — guardian linkage/household move, payment uniqueness/void, reason guard, returned notifications, close retry, write-freeze reason, missed-eval teacher notice and public duplicate/deadline guards (rolled back)';
end $$;
