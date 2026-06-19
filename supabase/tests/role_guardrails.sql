-- Guardrails regression suite (M6) — حماية آخر سوبر أدمن + خطر FK في الحذف النهائي.
-- بيشتغل كـ دور المايجريشن (RLS متخطّاة) ويعمل rollback دايمًا. النجاح => "GUARDRAILS OK".
-- شغّله عبر Supabase SQL editor / MCP execute_sql / psql -f.
--
-- بيغطّي:
--   1) trigger enforce_last_super_admin: مينفعش تشيل آخر صف super_admin (errcode 23514)،
--      بس تشيل واحد لما يكون فيه أكتر من واحد بينجح.
--   2) خطر الحذف النهائي: person مرجوع له من audit_log.actor_person_id (FK بدون cascade)
--      مينفعش يتحذف مباشرة (foreign_key_violation)، وبعد فصل المرجع بينجح. ده بيثبت
--      إن منطق delete-user (فصل المراجع قبل الحذف) ضروري وصحيح.
do $$
declare
  v_base int;
  v_p1 uuid; v_p2 uuid; v_p3 uuid;
begin
  -- ===== 1) حماية آخر سوبر أدمن =====
  select count(*) into v_base from public.role_assignment where role = 'super_admin';

  insert into public.person (full_name) values ('GR Super1') returning id into v_p1;
  insert into public.role_assignment (person_id, role) values (v_p1, 'super_admin');

  -- لو v_p1 هو السوبر أدمن الوحيد فعلاً (مفيش غيره من قبل) → الحذف لازم يتمنع.
  if v_base = 0 then
    begin
      delete from public.role_assignment where person_id = v_p1 and role = 'super_admin';
      raise exception 'GUARDRAILS FAIL: removed the last super_admin';
    exception
      when check_violation then null; -- متوقّع (23514)
    end;
  end if;

  -- ضيف سوبر أدمن تاني → دلوقتي حذف واحد لازم ينجح (مش الأخير).
  insert into public.person (full_name) values ('GR Super2') returning id into v_p2;
  insert into public.role_assignment (person_id, role) values (v_p2, 'super_admin');
  delete from public.role_assignment where person_id = v_p1 and role = 'super_admin';
  if exists (select 1 from public.role_assignment where person_id = v_p1 and role = 'super_admin') then
    raise exception 'GUARDRAILS FAIL: non-last super_admin delete did not apply';
  end if;

  -- ===== 2) خطر FK في الحذف النهائي =====
  insert into public.person (full_name) values ('GR Actor') returning id into v_p3;
  insert into public.audit_log (actor_person_id, action) values (v_p3, 'test_action');

  begin
    delete from public.person where id = v_p3;
    raise exception 'GUARDRAILS FAIL: deleted person despite audit_log FK';
  exception
    when foreign_key_violation then null; -- متوقّع (audit_log.actor_person_id بدون cascade)
  end;

  -- فصل المرجع (زي ما بيعمل delete-user) → الحذف لازم ينجح.
  update public.audit_log set actor_person_id = null where actor_person_id = v_p3;
  delete from public.person where id = v_p3;
  if exists (select 1 from public.person where id = v_p3) then
    raise exception 'GUARDRAILS FAIL: person delete after detach did not apply';
  end if;

  raise exception 'GUARDRAILS OK — last-super-admin guard + hard-delete FK detach invariants held (rolled back)';
end $$;
