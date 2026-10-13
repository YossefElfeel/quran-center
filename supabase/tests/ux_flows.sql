-- UX release regression suite. Run only after both UX migrations have committed.
-- All fixtures, test identities, notifications and payments roll back.
-- Success raises "UX OK"; a failed invariant raises "UX FAIL".
do $$
declare
  v_admin uuid; v_admin_uid uuid := gen_random_uuid();
  v_teacher uuid; v_student uuid; v_curr uuid; v_level uuid; v_circle uuid; v_new_circle uuid; v_new_teacher uuid;
  v_guardian uuid; v_guardian_uid uuid := gen_random_uuid(); v_household uuid;
  v_payment uuid; v_eval uuid; v_dev uuid; v_session uuid;
  v_month date := date_trunc('month', now() at time zone 'Africa/Cairo')::date;
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
  raise exception 'UX OK — guardian linkage, payment uniqueness/void, reason guard, returned notifications and close retry (rolled back)';
end $$;
