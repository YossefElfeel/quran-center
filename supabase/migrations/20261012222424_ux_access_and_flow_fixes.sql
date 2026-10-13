-- Guardian creation remains atomic; invitation links attach to the returned person.
drop function public.create_guardian_with_household(text, uuid, text, uuid, text);
create function public.create_guardian_with_household(
  p_guardian_name text, p_child_person_id uuid, p_relation text,
  p_household_id uuid default null, p_new_household_name text default null,
  p_guardian_phone text default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare v_guardian uuid; v_household uuid;
begin
  if auth.uid() is null or not (private.is_admin() or private.is_super_admin()) then
    raise exception 'only admins can create guardians' using errcode = '42501';
  end if;
  if coalesce(btrim(p_guardian_name), '') = '' or p_relation not in ('father', 'mother', 'other') then
    raise exception 'invalid guardian details' using errcode = '22023';
  end if;
  if p_guardian_phone is not null and p_guardian_phone !~ '^\+?[0-9]{10,15}$' then
    raise exception 'invalid phone' using errcode = '22023';
  end if;
  if not exists (select 1 from public.enrollment where student_person_id = p_child_person_id and status = 'active') then
    raise exception 'active student required' using errcode = '22023';
  end if;
  if p_household_id is null then
    insert into public.household(name) values (coalesce(nullif(btrim(p_new_household_name), ''), btrim(p_guardian_name))) returning id into v_household;
  else
    select id into v_household from public.household where id = p_household_id;
    if v_household is null then raise exception 'household not found' using errcode = '23503'; end if;
  end if;
  insert into public.person(full_name, is_minor, phone) values (btrim(p_guardian_name), false, p_guardian_phone) returning id into v_guardian;
  insert into public.role_assignment(person_id, role) values (v_guardian, 'parent');
  insert into public.guardian_link(guardian_person_id, student_person_id, relation) values (v_guardian, p_child_person_id, p_relation);
  insert into public.household_member(household_id, person_id, role) values (v_household, v_guardian, 'guardian');
  return v_guardian;
end $$;
revoke all on function public.create_guardian_with_household(text, uuid, text, uuid, text, text) from public, anon;
grant execute on function public.create_guardian_with_household(text, uuid, text, uuid, text, text) to authenticated;

create function public.update_guardian_details(p_guardian_id uuid,p_student_id uuid,p_name text,p_phone text,p_relation text,p_household_id uuid default null,p_new_household_name text default null)
returns void language plpgsql security definer set search_path='' as $$
declare v_household uuid;
begin
  if auth.uid() is null or not (private.is_admin() or private.is_super_admin()) then raise exception 'admin required' using errcode='42501'; end if;
  if coalesce(length(btrim(p_name)),0)<2 or p_relation not in ('father','mother','other') or (coalesce(p_phone,'')<>'' and p_phone !~ '^\+?[0-9]{10,15}$') then raise exception 'invalid details' using errcode='22023'; end if;
  if not exists(select 1 from public.guardian_link where guardian_person_id=p_guardian_id and student_person_id=p_student_id) then raise exception 'guardian link missing' using errcode='22023'; end if;
  select household_id into v_household from public.household_member where person_id=p_guardian_id;
  if p_household_id is not null then
    if not exists(select 1 from public.household where id=p_household_id) then raise exception 'household missing' using errcode='22023'; end if;
    v_household:=p_household_id;
  elsif v_household is null then
    if coalesce(btrim(p_new_household_name),'')='' then raise exception 'household required' using errcode='22023'; end if;
    insert into public.household(name) values(btrim(p_new_household_name)) returning id into v_household;
  end if;
  update public.person set full_name=btrim(p_name),phone=nullif(p_phone,'') where id=p_guardian_id;
  update public.guardian_link set relation=p_relation where guardian_person_id=p_guardian_id and student_person_id=p_student_id;
  insert into public.household_member(household_id,person_id,role) values(v_household,p_guardian_id,'guardian') on conflict do nothing;
end $$;
revoke all on function public.update_guardian_details(uuid,uuid,text,text,text,uuid,text) from public,anon;
grant execute on function public.update_guardian_details(uuid,uuid,text,text,text,uuid,text) to authenticated;

insert into public.system_settings(key, value) values ('center_phone', '""'::jsonb), ('center_name', '"دار تحفيظ القرآن"'::jsonb), ('center_address', '""'::jsonb) on conflict (key) do nothing;
create policy settings_public_contact on public.system_settings for select to anon using (key in ('center_phone', 'center_name', 'center_address'));
grant select on public.system_settings to anon;

alter table public.notification add column route_data jsonb not null default '{}'::jsonb;
-- Realtime publishes only rows authorized by the existing recipient RLS policy.
do $$ begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') and not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notification') then
    alter publication supabase_realtime add table public.notification;
  end if;
end $$;

-- Respect the existing void flag instead of introducing a second void representation.
-- A legacy duplicate deliberately blocks this index rather than silently altering receipts.
create unique index subscription_payment_one_per_month on public.subscription_payment(household_id, period_month) where not voided;
alter table public.subscription_payment add column method text not null default 'cash' check (method in ('cash', 'instapay', 'other'));
alter table public.subscription_payment add constraint subscription_payment_month_start check (extract(day from period_month) = 1) not valid;

-- Session lookup uses the center's business date, and keeps any still-open class visible.
create function public.today_session_status(p_circle_id uuid) returns jsonb
language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object('id', s.id, 'status', s.status, 'session_date', s.session_date,
    'present', (select count(*) from public.attendance a where a.session_id=s.id and a.status in ('present','late')),
    'absent', (select count(*) from public.attendance a where a.session_id=s.id and a.status='absent'),
    'tasmee', (select count(distinct d.enrollment_id) from public.daily_tasmee d where d.session_id=s.id))
  from public.circle_session s where s.circle_id=p_circle_id
    and (s.status='open' or s.session_date=(now() at time zone 'Africa/Cairo')::date)
  order by (s.status='open') desc, s.opened_at desc limit 1;
$$;
revoke all on function public.today_session_status(uuid) from public, anon;
grant execute on function public.today_session_status(uuid) to authenticated;

-- Closing is atomic and retry-safe; a retry never duplicates the plan or outcome.
create function public.close_session_with_plan(p_session_id uuid, p_revision jsonb default null,
  p_memorized_portion_id uuid default null) returns void
language plpgsql security invoker set search_path = '' as $$
declare v_session public.circle_session; v_revision uuid;
begin
  select * into v_session from public.circle_session where id=p_session_id for update;
  if v_session.id is null then raise exception 'session not found or forbidden' using errcode = '42501'; end if;
  if not (private.is_super_admin() or private.is_admin() or exists (select 1 from public.circle c where c.id=v_session.circle_id and c.teacher_id=private.current_person_id())) then
    raise exception 'only circle teacher/admin can close session' using errcode = '42501';
  end if;
  if v_session.status='closed' then return; end if;
  if p_revision is not null then
    insert into public.portion(name,surah_start,ayah_start,surah_end,ayah_end)
    values(p_revision->>'name',(p_revision->>'surah_start')::smallint,(p_revision->>'ayah_start')::smallint,(p_revision->>'surah_end')::smallint,(p_revision->>'ayah_end')::smallint) returning id into v_revision;
  end if;
  insert into public.session_plan(circle_id,revision_portion_id,set_by) values(v_session.circle_id,v_revision,private.current_person_id());
  if p_memorized_portion_id is not null then insert into public.session_outcome(session_id,memorized_portion_id) values(p_session_id,p_memorized_portion_id); end if;
  update public.circle_session set status='closed',closed_at=now() where id=p_session_id;
end $$;
revoke all on function public.close_session_with_plan(uuid,jsonb,uuid) from public, anon;
grant execute on function public.close_session_with_plan(uuid,jsonb,uuid) to authenticated;
create function public.open_circle_session(p_circle_id uuid, p_session_id uuid default null) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare v_id uuid := coalesce(p_session_id, gen_random_uuid());
begin
  if not (private.is_super_admin() or private.is_admin() or exists (select 1 from public.circle c where c.id=p_circle_id and c.teacher_id=private.current_person_id())) then
    raise exception 'only circle teacher/admin can open session' using errcode = '42501';
  end if;
  if exists (select 1 from public.circle_session where id=v_id and circle_id=p_circle_id) then return v_id; end if;
  insert into public.circle_session(id,circle_id,opened_by,session_date) values(v_id,p_circle_id,private.current_person_id(),(now() at time zone 'Africa/Cairo')::date);
  return v_id;
end $$;
revoke all on function public.open_circle_session(uuid,uuid) from public, anon;
grant execute on function public.open_circle_session(uuid,uuid) to authenticated;
create function public.update_center_settings(p_values jsonb) returns void
language plpgsql security invoker set search_path = '' as $$
declare v_key text; v_value jsonb;
begin
  if not private.is_super_admin() then raise exception 'only super admin can change settings' using errcode='42501'; end if;
  for v_key, v_value in select key,value from jsonb_each(p_values) loop
    update public.system_settings set value=v_value where key=v_key;
    if not found then raise exception 'setting not found: %',v_key; end if;
  end loop;
end $$;
revoke all on function public.update_center_settings(jsonb) from public,anon;
grant execute on function public.update_center_settings(jsonb) to authenticated;
alter table public.competition add column rules text, add column deadline timestamptz, add column prize text;

-- Trusted Edge Function entry point: atomic registration, application, and duplicate check.
create function public.submit_public_competition_application(p_competition_id uuid, p_name text, p_phone text,
  p_normalized_phone text, p_youtube_url text default null, p_consent boolean default false, p_category_id uuid default null) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_registration uuid; v_application uuid; v_comp public.competition;
begin
  if p_consent is not true or length(btrim(p_name)) < 2 or p_normalized_phone !~ '^[0-9]{10,15}$' then raise exception 'invalid application' using errcode='22023'; end if;
  select * into v_comp from public.competition where id=p_competition_id;
  if v_comp.id is null or v_comp.status <> 'open' or v_comp.deadline < now() then raise exception 'competition not open' using errcode='22023'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_normalized_phone,0));
  insert into public.public_registration(name,phone,normalized_phone,consent_ack) values(btrim(p_name),p_phone,p_normalized_phone,true) on conflict(normalized_phone) do nothing returning id into v_registration;
  if v_registration is null then select id into v_registration from public.public_registration where normalized_phone=p_normalized_phone; end if;
  if (select count(*) from public.competition_application where public_registration_id=v_registration and created_at>now()-interval '1 hour')>=10 then raise exception 'too many requests' using errcode='54000'; end if;
  select id into v_application from public.competition_application where competition_id=p_competition_id and public_registration_id=v_registration;
  if v_application is not null then return v_application; end if;
  insert into public.competition_application(competition_id,category_id,origin,public_registration_id,youtube_url) values(p_competition_id,p_category_id,'public',v_registration,p_youtube_url) returning id into v_application;
  return v_application;
end $$;
revoke all on function public.submit_public_competition_application(uuid,text,text,text,text,boolean,uuid) from public,anon,authenticated;
grant execute on function public.submit_public_competition_application(uuid,text,text,text,text,boolean,uuid) to service_role;
create function public.struggling_circle_ids() returns table(circle_id uuid)
language sql stable security invoker set search_path='' as $$
  select distinct e.circle_id from public.portion_ledger_entry l join public.enrollment e on e.student_person_id=l.student_person_id
  where e.status='active' and l.state='failed_retry' and l.attempts_count>=coalesce((select (value #>> '{}')::int from public.system_settings where key='struggle_failed_attempts'),3);
$$;
revoke all on function public.struggling_circle_ids() from public,anon;
grant execute on function public.struggling_circle_ids() to authenticated;
create function public.guardian_setup_status() returns table(
  guardian_id uuid, student_id uuid, guardian_name text, child_name text, relation text,
  has_login boolean, household_id uuid, household_name text, subscription_active boolean, children_count bigint
) language sql stable security invoker set search_path='' as $$
  select gl.guardian_person_id,gl.student_person_id,g.full_name,s.full_name,gl.relation::text,
    exists(select 1 from public.app_user u where u.person_id=g.id),h.id,h.name,
    exists(select 1 from public.subscription_payment p where p.household_id=h.id and not p.voided and p.period_month=date_trunc('month',now() at time zone 'Africa/Cairo')::date),
    (select count(*) from public.guardian_link links where links.guardian_person_id=g.id)
  from public.guardian_link gl join public.person g on g.id=gl.guardian_person_id join public.person s on s.id=gl.student_person_id
    left join public.household_member hm on hm.person_id=g.id left join public.household h on h.id=hm.household_id
  order by g.full_name;
$$;
revoke all on function public.guardian_setup_status() from public,anon;
grant execute on function public.guardian_setup_status() to authenticated;
